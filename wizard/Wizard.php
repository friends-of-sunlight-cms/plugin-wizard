<?php

namespace PluginWizard;

use Composer\Script\Event;
use RecursiveDirectoryIterator;
use RecursiveIteratorIterator;

/**
 * Class Wizard
 * @author Jirka Daněk <jdanek.eu>
 */
class Wizard
{
    /** @var Wizard|null */
    static private $instance = null;
    /** @var Event */
    private $event;
    /** @var string */
    private $plugin_id = '';
    /** @var string */
    private $plugin_name = '';

    /** @var bool */
    private $short = false;

    /**
     * @param Event $event
     */
    static function createFull(Event $event)
    {
        $wizard = new static($event);
        $wizard->run();
    }

    /**
     * @param Event $event
     */
    static function createShort(Event $event)
    {
        $wizard = new static($event);
        $wizard->setShort(true);
        $wizard->run();
    }

    /**
     * Wizard constructor.
     * @param Event $event
     */
    function __construct(Event $event)
    {
        $this->event = $event;
    }

    /**
     * Run processing
     */
    function run()
    {
        echo "\n";
        $this->processArguments();
        $this->execute();
        $this->cleanup();
        echo "\n\033[0;32m[DONE]\033[0m Your plugin is ready.\n";
        exit;
    }

    /**
     * Process arguments
     */
    function processArguments()
    {
        $args = $this->event->getArguments();

        $entered_name = $this->getEnteredName($args);
        $this->plugin_id = $this->slugify(strtolower($entered_name));
        $this->plugin_name = $this->slugify(ucwords($entered_name), '');
    }

    /**
     * @param bool $state
     */
    function setShort($state = true)
    {
        $this->short = $state;
    }

    /**
     * @return string
     */
    function getEnteredName($args)
    {
        if ((isset($args[0]) && ($args[0] !== "")) && (substr($args[0], 0, 2) !== '--')) {
            return implode(' ', $args);
        }

        $this->log("\033[0;31m[WARN]\033[0m You have not specified any plugin name, so the default name '\033[0;31mFooBar\033[0m' will be used.\n");
        $io = $this->event->getIO();
        if ($io->askConfirmation("\nDo you want to continue? [y/n] ", true)) {
            return "FooBar";
        }
    }

    /**
     * @param $string
     * @return string
     */
    function slugify($string, $replacement = '-')
    {
        $string = preg_replace('/[^a-zA-Z-\s]+/', '', $string);
        $string = str_replace(' ', $replacement, trim($string));
        return $string;
    }

    /**
     * @return string
     */
    function getPluginId()
    {
        return $this->plugin_id;
    }

    /**
     * @return string
     */
    function getPluginName()
    {
        return $this->plugin_name;
    }

    /**
     * @param string $message
     * @param array|null $params
     */
    function log($message = '', $params = null)
    {
        if (is_array($params) && count($params) > 0) {
            echo vsprintf($message, $params);
        } elseif ($params !== null) {
            echo sprintf($message, $params);
        } else {
            echo $message;
        }
    }

    /**
     * Creating plugin dirs and files
     */
    function execute()
    {
        echo "\n";
        $this->log("Plugin name set to '%s'\n\n", $this->getPluginName());

        // create dirs
        $this->log("Creating a directory structure:\n");

        // paths
        $base_path = ($this->short ? '' : 'plugins/extend/');
        $plugin_full_path = $base_path . $this->getPluginId();
        $plugin_lang_path = $plugin_full_path . '/Resources/languages';

        // create plugin dir
        $this->log(" - %s\n", $plugin_full_path);
        $this->createDirectory($plugin_full_path);

        // create lang dir
        $this->log(" - %s\n", $plugin_lang_path);
        $this->createDirectory($plugin_lang_path);

        // create plugin files
        $this->log("Creating plugin files.\n");
        $this->createPluginFiles($plugin_full_path);

        // create blank lang files
        $this->log("Creating language files.\n");
        $this->createLangFiles($plugin_lang_path, ['en', 'cs']);
    }

    /**
     * @param string $path path without trailing slash
     * @param int $mode
     * @param bool $recursive
     */
    private function createDirectory($path, $mode = 0777, $recursive = true)
    {
        if (!file_exists($path)) {
            mkdir($path, $mode, $recursive);
        }else{
            $io = $this->event->getIO();
            if ($io->askConfirmation("\033[0;31m[WARN]\033[0m Directory already exists, do you want to overwrite it? [y/n] ", true)) {
                mkdir($path, $mode, $recursive);
            }else{
                exit();
            }
        }
    }

    /**
     * @param $path
     */
    private function createPluginFiles($path)
    {
        // plugin.json
        $definition = [
            'name' => $this->getPluginName() . ' Plugin',
            'description' => 'Plugin description',
            'version' => '1.0',
            'api' => '^8.0',
            'url' => 'https://your-website.tld',
            'class' => $this->getPluginName() . 'Plugin',
            'langs' => [
                $this->getPluginId() => 'Resources/languages/',
            ],
            'events' => [],
            'events.web' => [],
            'events.admin' => [],
        ];
        file_put_contents($path . '/plugin.json', json_encode($definition, JSON_PRETTY_PRINT | JSON_UNESCAPED_SLASHES));
        $this->log(" - %s\n", 'plugin.json');

        // main plugin class
        $content = <<<'PHP'
        <?php
        
        namespace SunlightExtend\@@plugin.name@@;
        
        use Sunlight\Plugin\ExtendPlugin;
        
        class @@plugin.name@@Plugin extends ExtendPlugin
        {
        
        }
        PHP;

        $content = str_replace('@@plugin.name@@', $this->getPluginName(), $content);
        file_put_contents($path . '/' . $definition['class'] . '.php', $content);
        $this->log(" - %s.php\n", $definition['class']);
    }

    /**
     * @param string $path path without trailing slash
     * @param array $langs
     */
    private function createLangFiles($path, array $langs = ['en'])
    {
        foreach ($langs as $lang) {
            file_put_contents(
                $path . '/' . $lang . '.php',
                '<?php return ' . var_export([], true) . ';'
            );
            $this->log(" - %s.php\n", $lang);
        }
    }

    /**
     * Cleaning dist files
     */
    function cleanup()
    {
        $cleanup = false;

        $io = $this->event->getIO();
        if ($io->askConfirmation("\nDistribution complete, do you want to clean up temporary files? [y/n] ", true)) {
            $cleanup = true;
        }

        if ($cleanup) {
            // remove wizard dir
            $this->deleteDirectoryTree('wizard');
            // remove composer file
            unlink('composer.json');
            $this->log("\nCleanup! The wizard distribution files have been removed.\n");
        }
    }

    /**
     * Recursively remove directory contents
     * @param $dir
     */
    function deleteDirectoryTree($dir)
    {
        $it = new RecursiveDirectoryIterator($dir, RecursiveDirectoryIterator::SKIP_DOTS);
        $files = new RecursiveIteratorIterator($it, RecursiveIteratorIterator::CHILD_FIRST);
        foreach ($files as $file) {
            if ($file->isDir()) {
                rmdir($file->getRealPath());
            } else {
                unlink($file->getRealPath());
            }
        }
        rmdir($dir);
    }
}
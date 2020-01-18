Plugin Wizard
#############

A tool for making Sunlight CMS plugin architecture easier.


.. contents::

Requirements
************

- PHP 5.4.0+
- `Composer <https://getcomposer.org>`_


Usage
*****

::

    composer run-script (create|create-short) [name] [--]
    
    Modes:
      create             complete directory structure
      create-short       directory structure of plugin only
    
    Arguments:
      name                wanted plugin name [default: "FooBar"]
      
    Options:
      --no-interaction    automatic creation and cleaning
    
    


   
   
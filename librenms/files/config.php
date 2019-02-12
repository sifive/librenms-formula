{%- from "librenms/map.jinja" import librenms with context -%}
<?php

## Have a look in includes/defaults.inc.php for examples of settings you can set here. DO NOT EDIT defaults.inc.php!

### Database config
$config['db_host'] = '{{ librenms.config.db.host }}';
$config['db_user'] = '{{ librenms.config.db.user }}';
$config['db_pass'] = '{{ librenms.config.db.password }}';
$config['db_name'] = '{{ librenms.config.db.database }}';
$config['db']['extension'] = '{{ librenms.config.db.extension }}';// mysql or mysqli

### Memcached config - We use this to store realtime usage
$config['memcached']['enable']  = {{ librenms.config.memcached.enable }};
$config['memcached']['host']    = '{{ librenms.config.memcached.host }}';
$config['memcached']['port']    = {{ librenms.config.memcached.port }};

// This is the user LibreNMS will run as
//Please ensure this user is created and has the correct permissions to your install
$config['user'] = '{{ librenms.general.user }}';

### Locations - it is recommended to keep the default
#$config['install_dir']  = "{{ librenms.general.app_dir }}";

### This should *only* be set if you want to *force* a particular hostname/port
### It will prevent the web interface being usable form any other hostname
{% set base_url = '' -%}
{%- if librenms.config.base_url is not defined -%}
#$config['base_url']        = "http://librenms.company.com";
{%  else -%}
{%-   set base_url = librenms.config.base_url %}
{%- endif %}
{%- if librenms.config.base_path is defined -%}
{%    set base_url = base_url + librenms.config.base_path + '/' -%}
{%- endif %}
{%- if base_url != '' -%}
$config['base_url']        = "{{ base_url }}";
{%- endif %}

### Enable this to use rrdcached. Be sure rrd_dir is within the rrdcached dir
### and that your web server has permission to talk to rrdcached.
{% if librenms.config.rrdcached is not defined -%}
#$config['rrdcached']    = "unix:/var/run/rrdcached.sock";
{%- else -%}
$config['rrdcached']    = "{{ librenms.config.rrdcached }}";
{% endif %}

### Default community
$config['snmp']['community'] = array("{{ librenms.config.snmp_community }}");

### Authentication Model
$config['auth_mechanism'] = "{{ librenms.config.auth_mechanism }}"; # default, other options: ldap, http-auth
{% if librenms.config.http_auth_guest is not defined -%}
#$config['http_auth_guest'] = "guest"; # remember to configure this user if you use http-auth
{%- else -%}
$config['http_auth_guest'] = "{{ librenms.config.http_auth_guest }}"; # remember to configure this user if you use http-auth
{% endif %}

### List of RFC1918 networks to allow scanning-based discovery
{% if librenms.config.nets is not defined -%}
#$config['nets'][] = "10.0.0.0/8";
#$config['nets'][] = "172.16.0.0/12";
#$config['nets'][] = "192.168.0.0/16";
{%- else -%}
{% for net in librenms.config.nets -%}
$config['nets'][] = "{{ net }}";
{% endfor %}
{% endif %}

# following is necessary for poller-wrapper
# poller-wrapper is released public domain
$config['poller-wrapper']['alerter'] = {{ librenms.config.poller_wrapper }};
# Uncomment the next line to disable daily updates
{% if librenms.config.update == 'true' -%}
#$config['update'] = 0;
{%- else -%}
$config['update'] = 0;
{%- endif %}

# Uncomment to submit callback stats via proxy
{% if librenms.config.callback_proxy is not defined -%}
#$config['callback_proxy'] = "hostname:port";
{%- else -%}
$config['callback_proxy'] = "{{ librenms.config.callback_proxy }}";
{% endif %}

# Set default port association mode for new devices (default: ifIndex)
{% if librenms.config.default_port_association_mode is not defined -%}
#$config['default_port_association_mode'] = 'ifIndex';
{% else %}
$config['default_port_association_mode'] = '{{ librenms.config.default_port_association_mode }}';
{% endif %}

{% if grains['osfinger'] == 'CentOS Linux-7' %}
$config['fping'] = "/usr/sbin/fping";
{% endif %}
{%- if librenms.config.custom_options is defined %}
# Custom options
{%- for option in librenms.config.custom_options %}
{{ option }}
{%- endfor %}
{% endif %}

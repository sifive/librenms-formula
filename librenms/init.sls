{% from "librenms/map.jinja" import librenms with context %}
librenms_pkgs_install:
  pkg.installed:
    - names: {{ librenms.lookup.pkgs }}

librenms_directory:
  file.directory:
    - name: {{ librenms.general.home }}
    - user: {{ librenms.general.user }}
    - group: {{ librenms.general.group }}
    - require:
      - user: librenms_user
      - group: librenms_user

librenms_git:
  git.latest:
    - name: https://github.com/librenms/librenms.git
    - user: {{ librenms.general.user }}
    - target: {{ librenms.general.home }}
    - rev: {{ librenms.get('revision', 'master') }}
    - force_checkout: True
    - force_clone: True
    - force_fetch: True
    - force_reset: True
    - require:
      - pkg: librenms_pkgs_install
      - user: librenms_user
      - file: librenms_directory
    - unless: "LANG=C git status | grep -qv 'ahead\\|behind'"

{% if librenms.config.base_path is defined %}
{% set customfile = librenms.general.home + "/html/plugins/custom-htaccess.conf" %}
librenms_remove_custom_htaccess_if_setting_changed:
  cmd.run:
    - name: rm -f {{ customfile }}
    - unless: grep -q "RewriteBase {{ librenms.config.base_path }}$" {{ customfile }} 
librenms_custom_htaccess:
  file.copy:
    # html/plugins/* is ignored by .gitignore
    - name: {{ customfile }}
    - source: {{ librenms.general.home }}/html/.htaccess
    - force: true
    - require:
      - cmd: librenms_remove_custom_htaccess_if_setting_changed
    - onchanges:
      - git: librenms_git
      - cmd: librenms_remove_custom_htaccess_if_setting_changed
librenms_custom_rewrite_base:
  file.replace:
    - name: {{ customfile }}
    - pattern: 'RewriteBase .*$'
    - repl: "RewriteBase {{ librenms.config.base_path }}"
    - onchanges:
      - file: librenms_custom_htaccess
{% endif %}


librenms_config:
  file.managed:
    - name: {{ librenms.general.home }}/config.php
    - source: salt://librenms/files/config.php
    - template: jinja
    - user: {{ librenms.general.user }}
    - group: {{ librenms.lookup.webserver_group }}
    - mode: 640
    - require:
      - file: librenms_directory

librenms_user:
  user.present:
    - name: {{ librenms.general.user }}
    - gid: {{ librenms.general.group }}
    - groups:
      - {{ librenms.lookup.webserver_group }}
    - home: {{ librenms.general.home }}
    - shell: {{ librenms.lookup.nologin_shell}}
    - system: True
    - require:
      - group: librenms_user
  group.present:
    - name: {{ librenms.general.group }}
    - system: True
    - addusers:
      - {{ librenms.lookup.webserver_user }}

librenms_log_folder:
  file.directory:
    - name: {{ librenms.general.home }}/logs
    - user: {{ librenms.general.user }}
    - group: {{ librenms.general.group }}
    - recurse:
      - user
      - group
    - mode: 775
    - require:
      - git: librenms_git

librenms_rrd_folder:
  file.directory:
    - name: {{ librenms.general.home }}/rrd
    - user: {{ librenms.general.user }}
    - group: {{ librenms.general.group }}
    - recurse:
      - user
      - group
    - mode: 775
    - require:
      - git: librenms_git

librenms_crontab:
{% if grains['os_family'] == 'FreeBSD' %}
{# FreeBSD has no /etc/cron.d/ and a uses slightly different format #}
  cmd.run:
    - name: "sed 's#  librenms    #  #g' '{{ librenms.general.home }}/librenms.nonroot.cron' | sed 's#/opt/librenms#{{ librenms.general.home }}#g' > /var/cron/tabs/librenms"
    - onchanges:
      - git: librenms_git
  file.managed:
    - name: /var/cron/tabs/librenms
    - mode: 600
    - user: root
    - group: wheel
{% else %}
  file.managed:
    - name: /etc/cron.d/librenms
    - source: {{ librenms.general.home }}/librenms.nonroot.cron
    - require:
      - git: librenms_git
{% endif %}

librenms_compose_install:
  cmd.run:
    - name: ./scripts/composer_wrapper.php install --no-dev
    - runas: {{ librenms.general.user }}
    - cwd: {{ librenms.general.home }}
    - onchanges:
      - git: librenms_git

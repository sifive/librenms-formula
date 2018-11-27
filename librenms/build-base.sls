{% from "librenms/map.jinja" import librenms with context %}

include:
  - librenms

librenms_build_base:
  cmd.run:
    - cwd: {{ librenms.general.app_dir }}
    - runas: {{ librenms.general.user }}
    - name: php {{ librenms.general.app_dir }}/build-base.php
    - unless: "php {{ librenms.general.app_dir }}/validate.php | grep -E '^DB Schema.*[1-9][0-9]+$'"
    - require:
      - file: librenms_config

{% from "librenms/map.jinja" import librenms with context %}

include:
  - librenms

{% for user, option in librenms.config.users.items() %}
librenms_webuser_{{ user}}:
  cmd.run:
    - name: php adduser.php "{{ user }}" "{{ option.password }}" "{{ option.level }}" "{{ option.email }}"
    - cwd: {{ librenms.general.app_dir }}
    - onlyif: "php {{ librenms.general.app_dir }}/validate.php | grep -E '^DB Schema.*[1-9][0-9]+$'"
    - unless: mysql --user="{{ librenms.config.db.user }}" --database="{{ librenms.config.db.database }}" --password="{{ librenms.config.db.password }}" --execute="SELECT * FROM users WHERE username = '{{ user }}'" | grep "{{ user }}"
    - require:
      - file: librenms_config
{% endfor %}

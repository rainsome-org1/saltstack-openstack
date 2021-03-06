include:
  - openstack.init.control

/usr/local/src/glance-2013.1.2.tar.gz:
  file.managed:
    - source: salt://openstack/glance/files/glance-2013.1.2.tar.gz
    - mode: 644
    - user: root
    - group: root

glance-install:
  cmd.run:
    - name: cd /usr/local/src/ && tar zxf glance-2013.1.2.tar.gz && cd glance-2013.1.2/tools && pip-python install -r pip-requires && cd ../ && python setup.py install
    - unless: pip-python freeze | grep glance==2013.1.2
    - require:
      - pkg: openstack-pkg-init
      - file: /usr/local/src/glance-2013.1.2.tar.gz

/etc/glance/schema-image.json:
  file.managed:
    - source: salt://openstack/glance/files/schema-image.json
    - mode: 644
    - user: root
    - group: root

/etc/glance/policy.json:
  file.managed:
    - source: salt://openstack/glance/files/policy.json
    - mode: 644
    - user: root
    - group: root

/etc/glance/logging.cnf:
  file.managed:
    - source: salt://openstack/glance/files/logging.cnf
    - mode: 644
    - user: root
    - group: root

/etc/glance/glance-scrubber.conf:
  file.managed:
    - source: salt://openstack/glance/files/glance-scrubber.conf
    - mode: 644
    - user: root
    - group: root

/etc/glance/glance-registry-paste.ini:
  file.managed:
    - source: salt://openstack/glance/files/glance-registry-paste.ini
    - mode: 644
    - user: root
    - group: root

/etc/glance/glance-api-paste.ini:
  file.managed:
    - source: salt://openstack/glance/files/glance-api-paste.ini
    - mode: 644
    - user: root
    - group: root

/etc/glance/glance-cache.conf:
  file.managed:
    - source: salt://openstack/glance/files/glance-cache.conf
    - mode: 644
    - user: root
    - group: root

/etc/glance/glance-api.conf:
  file.managed:
    - source: salt://openstack/glance/files/glance-api.conf
    - mode: 644
    - user: root
    - group: root
    - template: jinja
    - defaults:
      MYSQL_SERVER: {{ pillar['glance']['MYSQL_SERVER'] }}
      GLANCE_USER: {{ pillar['glance']['GLANCE_USER'] }}
      GLANCE_PASS: {{ pillar['glance']['GLANCE_PASS'] }}
      GLANCE_DBNAME: {{ pillar['glance']['GLANCE_DBNAME'] }}
      RABBITMQ_HOST: {{ pillar['glance']['RABBITMQ_HOST'] }}
      RABBITMQ_PORT: {{ pillar['glance']['RABBITMQ_PORT'] }}
      RABBITMQ_USER: {{ pillar['glance']['RABBITMQ_USER'] }}
      RABBITMQ_PASS: {{ pillar['glance']['RABBITMQ_PASS'] }}
      AUTH_KEYSTONE_HOST: {{ pillar['glance']['AUTH_KEYSTONE_HOST'] }}
      AUTH_KEYSTONE_PORT: {{ pillar['glance']['AUTH_KEYSTONE_PORT'] }}
      AUTH_KEYSTONE_PROTOCOL: {{ pillar['glance']['AUTH_KEYSTONE_PROTOCOL'] }}
      AUTH_ADMIN_PASS: {{ pillar['glance']['AUTH_ADMIN_PASS'] }}

/etc/glance/glance-registry.conf:
  file.managed:
    - source: salt://openstack/glance/files/glance-registry.conf
    - mode: 644
    - user: root
    - group: root
    - template: jinja
    - defaults:
      MYSQL_SERVER: {{ pillar['glance']['MYSQL_SERVER'] }}
      GLANCE_USER: {{ pillar['glance']['GLANCE_USER'] }}
      GLANCE_PASS: {{ pillar['glance']['GLANCE_PASS'] }}
      GLANCE_DBNAME: {{ pillar['glance']['GLANCE_DBNAME'] }}
      AUTH_KEYSTONE_HOST: {{ pillar['glance']['AUTH_KEYSTONE_HOST'] }}
      AUTH_KEYSTONE_PORT: {{ pillar['glance']['AUTH_KEYSTONE_PORT'] }}
      AUTH_KEYSTONE_PROTOCOL: {{ pillar['glance']['AUTH_KEYSTONE_PROTOCOL'] }}
      AUTH_ADMIN_PASS: {{ pillar['glance']['AUTH_ADMIN_PASS'] }}

/var/log/glance:
  file.directory:
    - user: root
    - group: root

/var/lib/glance:
  file.directory:
    - user: root
    - group: root

/etc/init.d/openstack-glance-api:
  file.managed:
    - source: salt://openstack/glance/files/openstack-glance-api
    - mode: 755
    - user: root
    - group: root

/etc/init.d/openstack-glance-registry:
  file.managed:
    - source: salt://openstack/glance/files/openstack-glance-registry
    - mode: 755
    - user: root
    - group: root

glance-service:
  cmd.run:
    - name: chkconfig --add openstack-glance-api && chkconfig --add openstack-glance-registry
    - unless: chkconfig --list | grep glance
    - require:
      - file: /etc/init.d/openstack-glance-api
      - file: /etc/init.d/openstack-glance-registry

glance-mysql:
  mysql_database.present:
    - name: {{ pillar['glance']['GLANCE_DBNAME'] }}
    - require:
      - service: mysql-server
  mysql_user.present:
    - name: {{ pillar['glance']['GLANCE_USER'] }}
    - host: {{ pillar['glance']['HOST_ALLOW'] }}
    - password: {{ pillar['glance']['GLANCE_PASS'] }}
    - require:
      - mysql_database: glance-mysql
  mysql_grants.present:
    - grant: all
    - database: {{ pillar['glance']['DB_ALLOW'] }}
    - user: {{ pillar['glance']['GLANCE_USER'] }}
    - host: {{ pillar['glance']['HOST_ALLOW'] }}
    - require:
      - mysql_user: glance-mysql

glance-init:
  cmd.run:
    - name: glance-manage db_sync && touch /var/run/glance-dbsync.lock
    - require:
      - mysql_grants: glance-mysql
    - unless: test -f /var/run/glance-dbsync.lock

openstack-glance-api:
  service:
    - running
    - enable: True
    - watch: 
      - file: /etc/glance/schema-image.json
      - file: /etc/glance/policy.json
      - file: /etc/glance/logging.cnf
      - file: /etc/glance/glance-scrubber.conf
      - file: /etc/glance/glance-registry-paste.ini
      - file: /etc/glance/glance-api-paste.ini
      - file: /etc/init.d/openstack-glance-registry
      - file: /etc/glance/glance-api-paste.ini
      - file: /etc/glance/glance-cache.conf
      - file: /etc/glance/glance-api.conf
      - file: /etc/glance/glance-registry.conf
    - require:
      - cmd.run: glance-install
      - cmd.run: glance-service
      - cmd.run: glance-init

openstack-glance-registry:
  service:
    - running
    - enable: True
    - watch:
      - file: /etc/glance/schema-image.json
      - file: /etc/glance/policy.json
      - file: /etc/glance/logging.cnf
      - file: /etc/glance/glance-scrubber.conf
      - file: /etc/glance/glance-registry-paste.ini
      - file: /etc/glance/glance-api-paste.ini
      - file: /etc/init.d/openstack-glance-registry
      - file: /etc/glance/glance-api-paste.ini
      - file: /etc/glance/glance-cache.conf
      - file: /etc/glance/glance-api.conf
      - file: /etc/glance/glance-registry.conf
    - require:
      - cmd.run: glance-install
      - cmd.run: glance-service
      - cmd.run: glance-init


glance-data-init:
  file.managed:
    - name: /usr/local/bin/glance_data.sh
    - source: salt://openstack/glance/files/glance_data.sh
    - mode: 755
    - user: root
    - group: root
    - template: jinja
    - defaults:
      ADMIN_PASSWD: {{ pillar['glance']['ADMIN_PASSWD'] }} 
      ADMIN_TOKEN: {{ pillar['glance']['ADMIN_TOKEN'] }}
      CONTROL_IP: {{ pillar['glance']['CONTROL_IP'] }}
  cmd.run:
    - name: bash /usr/local/bin/glance_data.sh && touch /var/run/glance-datainit.lock
    - require:
      - file: glance-data-init
      - service: openstack-glance-api
      - service: openstack-glance-registry
    - unless: test -f /var/run/glance-datainit.lock

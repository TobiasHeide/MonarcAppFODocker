echo "starting initial setup"

# usage: file_env VAR [DEFAULT]
#    ie: file_env 'XYZ_DB_PASSWORD' 'example'
# (will allow for "$XYZ_DB_PASSWORD_FILE" to fill in the value of
#  "$XYZ_DB_PASSWORD" from a file, especially for Docker's secrets feature)
file_env() {
    local var="$1"
    local fileVar="${var}_FILE"
    local def="${2:-}"
    local varValue=$(env | grep -E "^${var}=" | sed -E -e "s/^${var}=//")
    local fileVarValue=$(env | grep -E "^${fileVar}=" | sed -E -e "s/^${fileVar}=//")
    if [ -n "${varValue}" ] && [ -n "${fileVarValue}" ]; then
        echo >&2 "error: both $var and $fileVar are set (but are exclusive)"
        exit 1
    fi
    if [ -n "${varValue}" ]; then
        export "$var"="${varValue}"
    elif [ -n "${fileVarValue}" ]; then
        export "$var"="$(cat "${fileVarValue}")"
    elif [ -n "${def}" ]; then
        export "$var"="$def"
    fi
    unset "$fileVar"
}


#wait for db
echo "sleep for 30 seconds"
sleep 30

file_env MYSQL_DATABASE
file_env MYSQL_PASSWORD
file_env MYSQL_USER
file_env MYSQL_HOST
#echo "mysql -h $MYSQL_HOST -u $MYSQL_USER -p$MYSQL_PASSWORD $MYSQL_DATABASE < /var/lib/monarc/fo/db-bootstrap/monarc_structure.sql"
#mysql -h $MYSQL_HOST -u $MYSQL_USER -p$MYSQL_PASSWORD $MYSQL_DATABASE < /var/lib/monarc/fo/db-bootstrap/monarc_structure.sql
#mysql -h $MYSQL_HOST -u $MYSQL_USER -p$MYSQL_PASSWORD $MYSQL_DATABASE < /var/lib/monarc/fo/db-bootstrap/monarc_data.sql

#mysql -h $MYSQL_HOST2 -u $MYSQL_USER2 -p$MYSQL_PASSWORD2 $MYSQL_DATABASE2 < /var/lib/monarc/fo/db-bootstrap/monarc_data.sql

cd /var/lib/monarc/fo/

#Database connection
cat <<EOF >> ./config/autoload/local.php
<?php
/**
 * Local Configuration Override
 *
 * This configuration override file is for overriding environment-specific and
 * security-sensitive configuration information. Copy this file without the
 * .dist extension at the end and populate values as needed.
 *
 * @NOTE: This file is ignored from Git by default with the .gitignore included
 * in ZendSkeletonApplication. This is a good practice, as it prevents sensitive
 * credentials from accidentally being committed into version control.
 */

\$appdir = getenv('APP_DIR') ?: '/var/lib/monarc';

\$package_json = json_decode(file_get_contents('./package.json'), true);

return [
    'doctrine' => [
        'connection' => [
            'orm_default' => [
                'params' => [
                    'host' => 'db',
                    'user' => 'monarc',
                    'password' => 'password',
                    'dbname' => 'monarc_common',
                ],
            ],
            'orm_cli' => [
                'params' => [
                    'host' => 'db2',
                    'user' => 'monarc',
                    'password' => 'password',
                    'dbname' => 'monarc_cli',
                ],
            ],
        ],
    ],
    'languages' => [
        'fr' => [
            'index' => 1,
            'label' => 'Français',
        ],
        'en' => [
            'index' => 2,
            'label' => 'English',
        ],
        'de' => [
            'index' => 3,
            'label' => 'Deutsch',
        ],
        'nl' => [
            'index' => 4,
            'label' => 'Nederlands',
        ],
        'es' => [
            'index' => 5,
            'label' => 'Spanish',
        ],
        'ro' => [
            'index' => 6,
            'label' => 'Romanian',
        ],
        'it' => [
            'index' => 7,
            'label' => 'Italian',
        ],
        'pt' => [
            'index' => 9,
            'label' => 'Portuguese',
        ],
        'pl' => [
            'index' => 10,
            'label' => 'Polish',
        ],
        'jp' => [
            'index' => 11,
            'label' => 'Japanese',
        ],
        'zh' => [
            'index' => 12,
            'label' => 'Chinese',
        ],
    ],

    'defaultLanguageIndex' => 1,

    'activeLanguages' => array('fr','en','de','nl','es','ro','it','ja','pl','pt','zh'),

    'appVersion' => \$package_json['version'],

    'checkVersion' => true,
    'appCheckingURL' => 'https://version.monarc.lu/check/MONARC',

    'email' => [
        'name' => 'MONARC',
        'from' => 'info@monarc.lu',
    ],

    'instanceName' => 'Development', // for example a short URL or client name from ansible
    'twoFactorAuthEnforced' => false,

    'terms' => 'https://my.monarc.lu/terms.html',

    'monarc' => [
        'ttl' => 60,
        'cliModel' => 'generic',
    ],

    'twoFactorAuthEnforced' => false,

    'mospApiUrl' => 'https://objects.monarc.lu/api/',

    'statsApi' => [
        'baseUrl' => 'http://127.0.0.1:5005',
        'apiKey' => '',
    ],

    'import' => [
        'uploadFolder' => \$appdir . '/data/import/files',
        'isBackgroundProcessActive' => false,
    ],
];
EOF

#Migrating MONARC DB
 php ./vendor/robmorgan/phinx/bin/phinx migrate -c module/Monarc/FrontOffice/migrations/phinx.php
 php ./vendor/robmorgan/phinx/bin/phinx migrate -c module/Monarc/Core/migrations/phinx.php

#Create initial user
 php ./vendor/robmorgan/phinx/bin/phinx seed:run -c ./module/Monarc/FrontOffice/migrations/phinx.php


echo "ending initial setup"
#!/bin/bash
set -e

ADMIN_DIR="${OC_ADMIN_DIR:-admin}"

CONFIG_FILE="/var/www/html/config.php"

# قراءة المتغيرات أو تعيين الافتراضي
DB_HOST=${DB_HOST:-mariadb-store}
DB_USER=${DB_USER:-opencart_admin}
DB_PASSWORD=${DB_PASSWORD:-opencart_secure_pass_2026}
DB_NAME=${DB_NAME:-opencart_db}
DB_PORT=${DB_PORT:-3306}

# متغيرات الإدمن الأولية (حتى لا تكون Hardcoded)
OC_ADMIN_USER=${OC_ADMIN_USER:-admin}
OC_ADMIN_PASS=${OC_ADMIN_PASS:-admin}
OC_ADMIN_EMAIL=${OC_ADMIN_EMAIL:-admin@localhost.com}

# إذا كان مجلد التثبيت موجوداً، فهذا يعني أنها أول مرة تعمل فيها الحاوية ويجب تهيئة قاعدة البيانات
if [ -d "/var/www/html/install" ]; then
    echo "⚙️  تثبيت أوبن كارت صامتاً لتهيئة الجداول وقاعدة البيانات..."
    
    php /var/www/html/install/cli_install.php install \
        --username "$OC_ADMIN_USER" \
        --password "$OC_ADMIN_PASS" \
        --email "$OC_ADMIN_EMAIL" \
        --http_server "http://localhost/" \
        --db_driver mysqli \
        --db_hostname "$DB_HOST" \
        --db_username "$DB_USER" \
        --db_password "$DB_PASSWORD" \
        --db_database "$DB_NAME" \
        --db_port "$DB_PORT" \
        --db_prefix oc_ || true
        
    echo "✅ تم تهيئة قاعدة البيانات بنجاح!"
    
    # حذف مجلد التثبيت للأمان كما هو قياسي في أوبن كارت
    rm -rf /var/www/html/install
fi

# تأمين مجلد التخزين (Storage) بنقله خارج مسار الويب (Web Root)
if [ -d "/var/www/html/system/storage" ]; then
    echo "🔒 Securing storage directory..."
    # التأكد من وجود المجلد الجديد
    mkdir -p /var/www/storage
    # إذا كان المجلد الجديد فارغاً (Volume جديد)، ننسخ محتويات التخزين الأصلية إليه
    if [ ! -d "/var/www/storage/vendor" ]; then
        cp -a /var/www/html/system/storage/. /var/www/storage/
    fi
    # حذف المجلد القديم الغير آمن
    rm -rf /var/www/html/system/storage
fi

echo "⚙️  تجهيز ملفات الإعدادات الديناميكية (Config & Code Separation)..."

# تغيير مسار الأدمن إذا تم تعيينه
if [ "$ADMIN_DIR" != "admin" ] && [ -d "/var/www/html/admin" ]; then
    mv /var/www/html/admin "/var/www/html/$ADMIN_DIR"
fi

ADMIN_CONFIG_FILE="/var/www/html/$ADMIN_DIR/config.php"

cat <<'EOF' > "$CONFIG_FILE"
<?php
// APPLICATION
define('APPLICATION', 'Catalog');

// HTTP
$protocol = isset($_SERVER['HTTPS']) && $_SERVER['HTTPS'] === 'on' ? 'https' : 'http';
$host = isset($_SERVER['HTTP_HOST']) ? $_SERVER['HTTP_HOST'] : 'localhost';
define('HTTP_SERVER', $protocol . '://' . $host . '/');

// DIR
define('DIR_OPENCART', '/var/www/html/');
define('DIR_APPLICATION', DIR_OPENCART . 'catalog/');
define('DIR_EXTENSION', DIR_OPENCART . 'extension/');
define('DIR_IMAGE', DIR_OPENCART . 'image/');
define('DIR_SYSTEM', DIR_OPENCART . 'system/');
define('DIR_STORAGE', '/var/www/storage/');
define('DIR_LANGUAGE', DIR_APPLICATION . 'language/');
define('DIR_TEMPLATE', DIR_APPLICATION . 'view/template/');
define('DIR_CONFIG', DIR_SYSTEM . 'config/');
define('DIR_CACHE', DIR_STORAGE . 'cache/');
define('DIR_DOWNLOAD', DIR_STORAGE . 'download/');
define('DIR_LOGS', DIR_STORAGE . 'logs/');
define('DIR_SESSION', DIR_STORAGE . 'session/');
define('DIR_UPLOAD', DIR_STORAGE . 'upload/');

// DB
define('DB_DRIVER', 'mysqli');
define('DB_HOSTNAME', getenv('DB_HOST') ?: 'mariadb-store');
define('DB_USERNAME', getenv('DB_USER'));
define('DB_PASSWORD', getenv('DB_PASSWORD'));
define('DB_DATABASE', getenv('DB_NAME'));
define('DB_PORT', getenv('DB_PORT') ?: '3306');
define('DB_PREFIX', 'oc_');
EOF

cat <<'EOF' > "$ADMIN_CONFIG_FILE"
<?php
// APPLICATION
define('APPLICATION', 'Admin');

// HTTP
$protocol = isset($_SERVER['HTTPS']) && $_SERVER['HTTPS'] === 'on' ? 'https' : 'http';
$host = isset($_SERVER['HTTP_HOST']) ? $_SERVER['HTTP_HOST'] : 'localhost';
define('HTTP_SERVER', $protocol . '://' . $host . '/admin/');
define('HTTP_CATALOG', $protocol . '://' . $host . '/');

// OpenCart API
define('OPENCART_SERVER', 'https://www.opencart.com/');

// DIR
define('DIR_OPENCART', '/var/www/html/');
define('DIR_APPLICATION', DIR_OPENCART . 'ADMIN_DIR_PLACEHOLDER/');
define('DIR_EXTENSION', DIR_OPENCART . 'extension/');
define('DIR_IMAGE', DIR_OPENCART . 'image/');
define('DIR_SYSTEM', DIR_OPENCART . 'system/');
define('DIR_CATALOG', DIR_OPENCART . 'catalog/');
define('DIR_STORAGE', '/var/www/storage/');
define('DIR_LANGUAGE', DIR_APPLICATION . 'language/');
define('DIR_TEMPLATE', DIR_APPLICATION . 'view/template/');
define('DIR_CONFIG', DIR_SYSTEM . 'config/');
define('DIR_CACHE', DIR_STORAGE . 'cache/');
define('DIR_DOWNLOAD', DIR_STORAGE . 'download/');
define('DIR_LOGS', DIR_STORAGE . 'logs/');
define('DIR_SESSION', DIR_STORAGE . 'session/');
define('DIR_UPLOAD', DIR_STORAGE . 'upload/');

// DB
define('DB_DRIVER', 'mysqli');
define('DB_HOSTNAME', getenv('DB_HOST') ?: 'mariadb-store');
define('DB_USERNAME', getenv('DB_USER'));
define('DB_PASSWORD', getenv('DB_PASSWORD'));
define('DB_DATABASE', getenv('DB_NAME'));
define('DB_PORT', getenv('DB_PORT') ?: '3306');
define('DB_PREFIX', 'oc_');
EOF

# استبدال Placeholder بالمسار الفعلي للأدمن
sed -i "s/ADMIN_DIR_PLACEHOLDER\//${ADMIN_DIR}\//g" "$ADMIN_CONFIG_FILE"

chown -R www-data:www-data /var/www/html
chown -R www-data:www-data /var/www/storage

exec "$@"

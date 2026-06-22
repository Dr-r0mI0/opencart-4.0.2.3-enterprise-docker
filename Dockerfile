# 1. استخدام الإصدار الرسمي المستقر والآمن
FROM php:8.2-apache

# 2. تثبيت الحزم الأساسية لنظام التشغيل والمكتبات اللازمة لإضافات PHP
RUN apt-get update && apt-get install -y \
    libpng-dev \
    libjpeg-dev \
    libfreetype6-dev \
    libzip-dev \
    libcurl4-openssl-dev \
    libonig-dev \
    libicu-dev \
    libxml2-dev \
    libmagickwand-dev \
    libmemcached-dev \
    libbz2-dev \
    libpq-dev \
    libgmp-dev \
    unzip \
    wget \
    zlib1g-dev \
    && rm -rf /var/lib/apt/lists/*

# 3. تثبيت وتفعيل إضافات PHP بالمعيار الشامل (لا مزيد من أخطاء الموديولات المفقودة)
# تم إضافة دعم PDO لـ PostgreSQL و Sockets و PCNTL و BZ2 لتوسعة العمل مستقبلاً
RUN docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install \
    mysqli \
    pdo_mysql \
    pdo_pgsql \
    pgsql \
    gd \
    zip \
    curl \
    mbstring \
    intl \
    bcmath \
    soap \
    opcache \
    exif \
    sockets \
    pcntl \
    bz2 \
    gmp \
    calendar

# 4. تثبيت وتفعيل مكتبة Imagick الاحترافية، بالإضافة إلى Redis و Memcached للتحسب للمستقبل
RUN pecl install imagick redis memcached \
    && docker-php-ext-enable imagick redis memcached

# 5. تفعيل مود الروابط الصديقة لمحركات البحث (Rewrite Module) وإضافات الأمان (Headers) في خادم Apache
RUN a2enmod rewrite headers

# 6. نسخ إعدادات PHP المخصصة لزيادة حجم الرفع والذاكرة وتسريع الكاش
COPY config/php.ini /usr/local/etc/php/conf.d/custom.ini
COPY config/opcache.ini /usr/local/etc/php/conf.d/opcache.ini

# 7. تحميل وفك ضغط كود أوبن كارت المستقر (الإصدار 4.0.2.3 لضمان استقرار الإنتاج)
WORKDIR /var/www/html
RUN wget https://github.com/opencart/opencart/releases/download/4.0.2.3/opencart-4.0.2.3.zip -O /tmp/opencart.zip \
    && unzip /tmp/opencart.zip -d /tmp/opencart-extracted \
    && cp -a /tmp/opencart-extracted/opencart-4.0.2.3/upload/. /var/www/html/ \
    && rm -rf /tmp/opencart.zip /tmp/opencart-extracted

# 8. تجهيز ملفات Configs فارغة مبدئياً ليقوم السكربت بالكتابة عليها ديناميكياً
RUN touch config.php admin/config.php \
    && chown -R www-data:www-data /var/www/html

# 9. نسخ وتجهيز سكربت الإقلاع الذكي الخاص بالأتمتة
COPY scripts/entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

# تحديد نقطة البداية لتشغيل الحاوية
ENTRYPOINT ["entrypoint.sh"]
CMD ["apache2-foreground"]

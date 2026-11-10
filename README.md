# NurseRoster — نظام روستر التمريض

تطبيق Laravel 12 تجريبي باللغة العربية لإدارة رغبات التمريض والروستر الشهري.

## الوضع الحالي
هذا المستودع يحتوي على **ملفات التطبيق المخصصة فقط** وليس مشروع Laravel كاملًا مستقلًا. يجب إنشاء Laravel قياسي ونسخ ملفات المستودع فوقه. **لم يتم نشر التطبيق أو إجراء اختبارات تشغيل شاملة بعد.**

## الرموز
- E صباحي
- N ليلي
- 8 ثماني ساعات
- # راحة

## التشغيل على Ubuntu أو بيئة PHP محلية
المتطلبات: PHP 8.2+ مع امتدادات MySQL وXML وZIP وMbstring وGD، Composer، MySQL 8، وGit.

```bash
composer create-project laravel/laravel nurseroster "^12.0"
git clone https://github.com/khaledmoon64/rostar.git nurseroster-source
cd nurseroster
cp -r ../nurseroster-source/app/Models/* app/Models/
cp -r ../nurseroster-source/app/Http/Controllers/* app/Http/Controllers/
cp -r ../nurseroster-source/resources/views/* resources/views/
cp ../nurseroster-source/routes/web.php routes/web.php
cp ../nurseroster-source/database/seeders/DatabaseSeeder.php database/seeders/
cp ../nurseroster-source/database/migrations/2026_11_10_000001_create_roster_tables.php database/migrations/
rm database/migrations/0001_01_01_000000_create_users_table.php
composer require phpoffice/phpspreadsheet:^4.0
```

أنشئ قاعدة بيانات MySQL ومستخدمًا خاصًا بها. عدّل ملف `.env` في مشروع Laravel وأضف:
```ini
DB_CONNECTION=mysql
DB_HOST=127.0.0.1
DB_PORT=3306
DB_DATABASE=nurseroster
DB_USERNAME=nurseroster
DB_PASSWORD=SET_DATABASE_PASSWORD
ROSTER_ADMIN_EMAIL=admin@example.com
ROSTER_ADMIN_PASSWORD=SET_A_LONG_UNIQUE_PASSWORD
APP_DEBUG=false
```
ثم:
```bash
php artisan key:generate
php artisan migrate
php artisan db:seed
php artisan serve --host=127.0.0.1 --port=8000
```
افتح http://127.0.0.1:8000/login وسجّل ببريد المدير وكلمة المرور التي اخترتها.

## Excel
لا ترفع بيانات الموظفين الحقيقية إلى مستودع Public. استورد ملف Excel من داخل شاشة المدير بعد التشغيل. يجب أن تحتوي الورقة الأولى على عمودي `رقم الموظف` و`اسم الممرض`، وصف ثاني لأرقام الأيام، ثم بيانات الموظفين.

## حدود النسخة
- التوزيع يدوي؛ لا توجد خوارزمية تغطية آلية أو ضمان للراحة بين الشيفتات.
- التصدير CSV وليس PDF.
- لا توجد استعادة كلمة مرور ذاتية.
- لا تستخدمه لجدولة فعلية أو تفتح خادم التطوير على الإنترنت قبل مراجعة الأمان والاختبار.
- GitHub Pages لا يدعم PHP/MySQL؛ النشر يحتاج خادم Laravel منفصلًا.

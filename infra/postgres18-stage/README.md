# PostgreSQL 18 staging على Oracle

دي قاعدة PostgreSQL (قاعدة بيانات علائقية) فاضية للتجارب المرحلية على سيرفر Oracle. مش قاعدة إنتاج، ومفيش بيانات أو migrations (ملفات تغييرات مخطط قاعدة البيانات) أو مستخدمين من Supabase اتنقلوا لها. تشغيلها ما معناهش إن تطبيق شطب اتنشر.

## 1. مكونات الحزمة

`Docker Compose` (أداة بتعرّف الخدمات والشبكة والتخزين من ملف إعداد واحد) بيعرّف `db` وخدمة API التجريبية ضمن المشروع `shattab-pg18-stage`. أقسام تشغيل القاعدة بتطلب خدمة `db` فقط؛ تشغيل API موضح منفصلًا في القسم 6.

| الإعداد | معناه وسبب استخدامه |
| --- | --- |
| `Docker image` (نسخة برنامج جاهزة للتشغيل) `postgres:18.6-bookworm` مع `digest` (بصمة ثابتة لمحتوى الصورة) | يثبت نفس نسخة البرنامج بدل الاعتماد على tag متغير. الـ digest المختار يدعم `ARM64` (معمارية معالجات ARM) و`AMD64`. Docker يشغّل النسخة داخل `container` (بيئة تشغيل معزولة نسبيًا عن النظام المضيف). |
| `POSTGRES_DB` و`POSTGRES_USER` | ينشئ قاعدة `shattab_stage` وحساب إدارة خاصًا بالتجربة اسمه `shattab_stage_admin`. الحساب إداري، وممنوع استخدامه كحساب تطبيق أو وضعه في Flutter أو المتصفح. |
| `POSTGRES_PASSWORD_FILE` و`secrets` | كلمة السر تتقري من ملف على السيرفر فقط، بدل وضع قيمتها في الملف أو أمر التشغيل. الملف محدود الصلاحية لكنه مش مشفر على القرص؛ مدير السيرفر وDocker يقدروا يقرؤوه. |
| `scram-sha-256` | `SCRAM-SHA-256` (آلية تحقق بكلمة السر بطريقة تحدٍ واستجابة، من غير إرسال كلمة السر نفسها على الشبكة). اتصال TCP (اتصال قاعدة البيانات عبر الشبكة) هيستخدمها؛ اتصال Unix socket (قناة محلية داخل الحاوية) يسمح به إعداد `trust` للتجهيز المحلي فقط. |
| `PGDATA=/var/lib/postgresql/18/docker` و`pgdata:/var/lib/postgresql` | مسار البيانات الصحيح لصورة PostgreSQL 18. الـ `volume` (مساحة دائمة بيديرها Docker) منفصل عن PostgreSQL 17 الموجود في `shattab-lab`. ما تنقلش أو تركب بيانات التجربة القديمة هنا. |
| شبكة `internal: true` ومن غير `ports` | الشبكة مخصصة للحاويات الداخلية، ومنفذ 5432 مش منشور على السيرفر. مدير المضيف وDocker يفضلوا قادرين على إدارة الحاوية؛ ده مش عزل كامل عن مسؤول السيرفر. |
| `mem_limit`, `cpus`, `pids_limit`, `shm_size` | حدود قصوى للتجربة: 1 GiB RAM (ذاكرة التشغيل)، و1 CPU (معالج)، و128 عملية، و128 MiB ذاكرة مشتركة. الحدود تقلل التنافس على موارد السيرفر لكنها مش اختبار أداء ولا ضمان سعة. |
| `restart: "no"` | يمنع قاعدة التجربة من الرجوع تلقائيًا بعد إعادة تشغيل السيرفر، عشان ما تستهلكش موارد من غير تشغيل مقصود. |
| `healthcheck` | يفحص هل PostgreSQL جاهز للاتصال. `pg_isready` لوحده ما يثبتش صحة كلمة السر؛ عشان كده `verify.py` يعمل كمان اتصال TCP بكلمة السر. |
| سجلات محدودة و`no-new-privileges` | سجلات Docker تتحدد بثلاث ملفات، كل ملف 10 MiB، والعملية ما تكتسبش صلاحيات إضافية. ده يقلل بعض المخاطر واستهلاك القرص، لكنه مش حد لحجم بيانات قاعدة البيانات. |

قيم `POSTGRES_*` بتجهّز قاعدة فاضية أول مرة فقط. تغيير ملف السر بعد إنشاء الـ volume ما يغيّرش كلمة السر داخل قاعدة موجودة.

## 2. إنشاء مساحة العمل والسر على السيرفر

الخطوات دي على `Ubuntu SSH` (جلسة اتصال آمنة لإدارة سيرفر Ubuntu). لازم مسؤول التنفيذ يعمل فحصًا جديدًا قبلها مباشرة: يتأكد إن المسار وموارد Docker الجديدة مش موجودة، وإن `shattab-lab` سليم. لو في أي اختلاف أو ملف موجود، يقف للمراجعة وما يكتبش فوقه.

أنشئ مجلد المرحلة فقط كمستخدم `ubuntu`. ما تنشئش `secrets/` يدويًا؛ أداة الإعداد هتنشئه داخل المجلد المثبّت وتراجع ملكيته وصلاحيته:

```bash
sudo -u ubuntu mkdir -m 700 /home/ubuntu/shattab-pg18-stage
```

ارفع الملفات غير السرية الأولية من `Windows PowerShell` (طرفية ويندوز). احسب بصمة المصدر محليًا، وبعدها ارفع الملفات؛ ما تحطش كلمة سر أو مفتاح في الأمر:

```powershell
Get-FileHash .\infra\postgres18-stage\compose.yaml, .\infra\postgres18-stage\verify.py, .\infra\postgres18-stage\create_api_secret.py -Algorithm SHA256
```

```powershell
scp .\infra\postgres18-stage\compose.yaml .\infra\postgres18-stage\verify.py .\infra\postgres18-stage\create_api_secret.py .\infra\postgres18-stage\README.md ubuntu@<SERVER>:/home/ubuntu/shattab-pg18-stage/
```

استبدل `<SERVER>` بعنوان السيرفر المعروف عندك قبل تنفيذ `scp`.

على `Ubuntu SSH`، اعمل مجلد أدوات جديد مملوك لـ`root`، وثبّت نسختي التحقق والسر فيه بصلاحية قراءة/تشغيل للـroot فقط. لو المجلد موجود بالفعل، وقف وما تستبدلش نسخه. بعد التثبيت قارن بصمات الملفين مع `Get-FileHash` اللي ظهرت عندك في PowerShell؛ لازم تتطابق حرفيًا قبل تشغيل أي سكريبت بصلاحية `sudo`:

```bash
sudo test ! -e /root/shattab-pg18-stage-tools && sudo test ! -L /root/shattab-pg18-stage-tools && sudo mkdir -m 700 /root/shattab-pg18-stage-tools && sudo install -o root -g root -m 500 /home/ubuntu/shattab-pg18-stage/verify.py /root/shattab-pg18-stage-tools/verify.py && sudo install -o root -g root -m 500 /home/ubuntu/shattab-pg18-stage/create_api_secret.py /root/shattab-pg18-stage-tools/create_api_secret.py && sudo sha256sum /root/shattab-pg18-stage-tools/verify.py /root/shattab-pg18-stage-tools/create_api_secret.py
```

نسخة `root-only` مهمة لأن مجلد المرحلة نفسه مملوك لـ`ubuntu`؛ تشغيل ملف Python بصلاحية `sudo` من مجلد يقدر `ubuntu` يغيّره يسمح بتبديل الكود قبل التنفيذ. لو بصمة أي helper مختلفة أو مجلد الأدوات موجود، وقف للمراجعة. ما تعيدش إنشاء مجلد الأدوات ولا تستبدل الملفات الموجودة تلقائيًا.

ثبّت ملف Compose (تعريف الخدمات والشبكات والـvolumes) كـ`snapshot` (نسخة ثابتة من الإعداد محفوظة باسم مرتبط ببصمتها) مملوك لـ`root` ومتاح للقراءة فقط. الاسم مبني على بصمة SHA-256 (بصمة رقمية لمحتوى الملف) المحسوبة من `compose.yaml` المحلي. التثبيت بيبدأ فقط لو الملف المستهدف غير موجود؛ لو موجود مسبقًا، ما تستبدلوش: استخدم فحص القراءة فقط تحته، وكمّل فقط لو هو ملف حقيقي مملوك لـ`root` وصلاحيته `444` وبصمته تطابق البصمة المحلية:

```bash
sudo test ! -e /root/shattab-pg18-stage-tools/compose.3216004984ca41882f0cc59b6e625e4f88da2f08575e484d7167a5b0c783d008.yaml && sudo test ! -L /root/shattab-pg18-stage-tools/compose.3216004984ca41882f0cc59b6e625e4f88da2f08575e484d7167a5b0c783d008.yaml && sudo install -o root -g root -m 444 /home/ubuntu/shattab-pg18-stage/compose.yaml /root/shattab-pg18-stage-tools/compose.3216004984ca41882f0cc59b6e625e4f88da2f08575e484d7167a5b0c783d008.yaml && sudo stat -c '%a %u:%g %n' /root/shattab-pg18-stage-tools/compose.3216004984ca41882f0cc59b6e625e4f88da2f08575e484d7167a5b0c783d008.yaml && sudo sha256sum /root/shattab-pg18-stage-tools/compose.3216004984ca41882f0cc59b6e625e4f88da2f08575e484d7167a5b0c783d008.yaml
```

لو الـsnapshot موجود بالفعل، نفّذ الفحص ده بدل أمر التثبيت؛ المتوقع `444 0:0` وبصمة `3216004984ca41882f0cc59b6e625e4f88da2f08575e484d7167a5b0c783d008`. قارن قيمة البصمة نفسها؛ اختلاف حالة الحروف بين PowerShell و`sha256sum` مجرد تنسيق. لو النوع أو المالك أو الصلاحية أو البصمة مختلفين، وقف وما تستبدلش الملف:

```bash
sudo test -f /root/shattab-pg18-stage-tools/compose.3216004984ca41882f0cc59b6e625e4f88da2f08575e484d7167a5b0c783d008.yaml && sudo test ! -L /root/shattab-pg18-stage-tools/compose.3216004984ca41882f0cc59b6e625e4f88da2f08575e484d7167a5b0c783d008.yaml && sudo stat -c '%a %u:%g %n' /root/shattab-pg18-stage-tools/compose.3216004984ca41882f0cc59b6e625e4f88da2f08575e484d7167a5b0c783d008.yaml && sudo sha256sum /root/shattab-pg18-stage-tools/compose.3216004984ca41882f0cc59b6e625e4f88da2f08575e484d7167a5b0c783d008.yaml
```

الـsnapshot الحالي هو المحتوى الذي راجعناه محليًا. الخيار `--project-directory` (بيحدد مجلد المشروع الأساسي اللي Compose بيحل منه المسارات النسبية) هيستخدم `/home/ubuntu/shattab-pg18-stage` في كل الأوامر، رغم إن ملف الإعداد الموثوق محفوظ خارج المجلد ده. أي تحديث لاحق لملف Compose، بما فيه تحديث جديد لخدمة API، لازم يطلع ببصمة واسم ملف جديدين؛ نحتفظ بالـsnapshot القديم، ونراجع التغيير ونثبت النسخة الجديدة غيابياً بوضع `0444`، ونقارن بصمتها قبل الاستخدام. بعد المراجعة فقط، نحدّث مسار `COMPOSE_FILE` في `verify.py` وكل مراجع `-f` في الدليل. ما نستخدمش snapshot موجودة ببصمة مختلفة وما نكتبش فوق نسخة سابقة.

بعد مطابقة البصمات، أنشئ مجلد الأسرار وسر PostgreSQL التجريبي بأداة الـbootstrap (إعداد أولي آمن). الأداة تثبّت مجلد المرحلة، وتنشئ `secrets/` نسبيًا له فقط لو مش موجود، وتتحقق من المجلد المفتوح عبر `fstat`. لو `secrets/` موجود، لازم يكون بالفعل مجلدًا حقيقيًا مملوكًا لـ`root` بوضع `0700`. الملف بيتنشأ بدون استبدال، وبمالك UID مجلد المرحلة ووضع `0600`؛ القيمة العشوائية لا تظهر على الشاشة. ما تستخدمش shell redirection أو `chown`/`chmod` على مسارات الأسرار:

```bash
sudo python3 /root/shattab-pg18-stage-tools/create_api_secret.py --bootstrap-postgres-password
```

لو ظهر `PASS` يبقى الأداة تحققت من الـmetadata (بيانات الملكية والنوع والصلاحيات) من خلال أوصاف الملفات المفتوحة، من غير عرض محتوى السر. لو ظهر خطأ أو ملف موجود، سيب الحالة زي ما هي ووقف؛ ما تحذفش ملف وما تعيدش المحاولة تلقائيًا. سر قاعدة البيانات مش مشفر على القرص؛ مسؤول النظام وDocker يقدروا يقرؤوه. ما تستخدمش `cat` أو `echo` لملف السر، وما تضيفوش لأي نسخة احتياطية أو repository (مستودع ملفات المشروع) من غير قرار منفصل.

## 3. فحص الإعداد وتشغيل القاعدة

كل الأوامر الجاية على السيرفر ومن داخل `/home/ubuntu/shattab-pg18-stage`. `sudo` يشغل Docker بصلاحيات مدير النظام؛ الوصول لـ Docker daemon (خدمة إدارة الحاويات) يعادل صلاحيات واسعة على السيرفر.

```bash
cd /home/ubuntu/shattab-pg18-stage
```

تحقق من الملف من غير طباعة الإعدادات:

```bash
sudo docker compose --env-file /dev/null --project-directory /home/ubuntu/shattab-pg18-stage -f /root/shattab-pg18-stage-tools/compose.3216004984ca41882f0cc59b6e625e4f88da2f08575e484d7167a5b0c783d008.yaml -p shattab-pg18-stage config --quiet
```

`--env-file /dev/null` يمنع Compose من تحميل ملف `.env` تلقائي، و`-f` يحدد ملف الإعداد، و`-p` يثبت اسم المشروع، و`--quiet` يطلب التحقق من غير عرض القيم. النجاح عادةً بيرجع من غير output؛ أي خطأ يوقف التشغيل للمراجعة.

نزّل الصورة المثبتة، وبعدها شغّل الخدمة في الخلفية:

```bash
sudo docker compose --env-file /dev/null --project-directory /home/ubuntu/shattab-pg18-stage -f /root/shattab-pg18-stage-tools/compose.3216004984ca41882f0cc59b6e625e4f88da2f08575e484d7167a5b0c783d008.yaml -p shattab-pg18-stage pull db
```

```bash
sudo docker compose --env-file /dev/null --project-directory /home/ubuntu/shattab-pg18-stage -f /root/shattab-pg18-stage-tools/compose.3216004984ca41882f0cc59b6e625e4f88da2f08575e484d7167a5b0c783d008.yaml -p shattab-pg18-stage up -d db
```

`pull` (تنزيل الصورة) يستهلك مساحة وبيانات اتصال. `up -d` ينشئ الشبكة الداخلية والـ volume والحاوية ويشغّل قاعدة البيانات. أول تشغيل فقط يهيّئ قاعدة فارغة؛ ما بيشغّلش migrations لشطب.

راجع الحالة:

```bash
sudo docker compose --env-file /dev/null --project-directory /home/ubuntu/shattab-pg18-stage -f /root/shattab-pg18-stage-tools/compose.3216004984ca41882f0cc59b6e625e4f88da2f08575e484d7167a5b0c783d008.yaml -p shattab-pg18-stage ps db
```

استنى لحد ما الحالة تبقى `healthy`، وبعدين شغّل أداة التحقق:

```bash
sudo python3 /root/shattab-pg18-stage-tools/verify.py
```

الأداة بتتحقق من اسم المشروع والحاوية، إصدار الصورة ومعمارية `ARM64`، الحالة الصحية، حدود الموارد، سياسة عدم إعادة التشغيل، تدوير السجلات، الـ volume ومسار PG18، الشبكة الداخلية وغياب نشر المنافذ. بعدها بتستخدم عميل PostgreSQL مؤقتًا داخل نفس الشبكة لتثبت دخول TCP بكلمة السر، ونسخة `18.6` ورقم `180006`، ووجود إعداد `SCRAM`، وعدم وجود جداول أو علاقات تطبيقية. المتوقع `PASS` من غير أي كلمة سر.

ملف `pgpass` (ملف مؤقت يمرر بيانات الدخول لعميل PostgreSQL) بيتكتب في `/tmp` خارج المشروع بصلاحية `600`. الأداة ما بتحطش كلمة السر في وسيطات الأوامر أو السجلات، وما بتحذف الملف إلا بعد ما تأكد إزالة حاوية العميل. لو تعذر تأكيد التنظيف، الأداة تفشل وتسيب الملف بصلاحية محمية وتطبع مساره فقط للمراجعة؛ ما تحذفهش قبل التأكد من عدم وجود حاوية بتستخدمه.

## 4. الإيقاف والاستئناف الآمن

بعد نجاح التحقق، أوقف الخدمة مع الاحتفاظ بالحاوية والبيانات والسر:

```bash
sudo docker compose --env-file /dev/null --project-directory /home/ubuntu/shattab-pg18-stage -f /root/shattab-pg18-stage-tools/compose.3216004984ca41882f0cc59b6e625e4f88da2f08575e484d7167a5b0c783d008.yaml -p shattab-pg18-stage stop db
```

`stop` يوقف قاعدة البيانات ويحرر CPU وRAM، لكنه لا يحذف الـ volume. ما تستخدمش `down -v` أو `docker volume rm` أو أوامر تنظيف في هذه المرحلة.

للاستئناف لاحقًا بعد التأكد من الحالة والاحتياج، شغّلها صراحةً:

```bash
sudo docker compose --env-file /dev/null --project-directory /home/ubuntu/shattab-pg18-stage -f /root/shattab-pg18-stage-tools/compose.3216004984ca41882f0cc59b6e625e4f88da2f08575e484d7167a5b0c783d008.yaml -p shattab-pg18-stage start db
```

بعد `start` راجع `ps db` لحد `healthy`، ثم أعد `sudo python3 /root/shattab-pg18-stage-tools/verify.py`. ثبات اسم المشروع والـ volume مهم؛ تغيير الاسم ممكن ينشئ volume جديدًا فاضيًا.

لو أي فحص فشل بعد الإنشاء، أوقف خدمة `shattab-pg18-stage` وحدها واترك الـ volume والسر للتحقيق. ما توقفش أو تعدّل `shattab-lab`، وما تحذفش بيانات لأي سبب كجزء من الرجوع. إيقاف هذه القاعدة لا يغيّر قواعد firewall أو قواعد OCI ولا يفتح المنفذ 5432.

## 5. حدود الدليل

نجاح فحص الإعداد محليًا ما يثبتش إن الملفات اترفعت أو إن قاعدة البيانات اشتغلت على Oracle. التشغيل الفعلي لازم يتوثق من مخرجات السيرفر ومقارنة حالة `shattab-lab` قبل وبعد. قاعدة staging دي فاضية ومؤقتة؛ مش نسخة احتياطية، ومش قاعدة تطبيق، ومش دليل نشر أو جاهزية إنتاج.

## 6. تكامل API تجريبي — مخطط فقط، غير منفذ

القسم ده يشرح تجهيز اتصال داخلي لخدمة API (واجهة خدمات بتستقبل طلبات التطبيقات) الموجودة في `api/` مع قاعدة PostgreSQL 18 التجريبية. الـ API لسه health-only (وظيفته الحالية فحص إن العملية وقاعدة البيانات شغالين) وبيشغّل استعلام ثابت `SELECT 1`. مفيش جداول شطب أو بيانات مستخدمين أو ميزات تطبيقية في النطاق ده، ومش بديل لـ Supabase.

**مفيش خطوة في القسم ده اتنفذت على Oracle.** رفع الملفات أو تشغيل الخدمة أو إنشاء دور/سر على السيرفر يحتاج موافقة صريحة منفصلة بعد مراجعة التغيير المحلي ده. ما تنفذش الخطوات دي أثناء مراجعة الكود.

### 6.1 شكل الاتصال وحدوده

| الإعداد | القيمة والخبرة المطلوبة |
| --- | --- |
| مصدر البناء | ملفات API غير السرية فقط في `/home/ubuntu/shattab-pg18-stage/api-source/`. ملف Compose الموثوق موجود تحت `/root/shattab-pg18-stage-tools/`، و`--project-directory /home/ubuntu/shattab-pg18-stage` يثبت حل المسار النسبي `./api-source` داخل مجلد المرحلة. |
| شبكة API | شبكة Docker داخلية `shattab-pg18-stage_db_internal` فقط؛ اسم خدمة قاعدة البيانات داخل الشبكة `db`. |
| المنفذ | API يستمع على `3000` داخل شبكة الحاويات فقط. مفيش `ports` في Compose؛ بالتالي لا يوجد نشر لمنفذ API أو PostgreSQL على السيرفر. |
| اتصال قاعدة البيانات | قاعدة `shattab_stage` ودور `shattab_api` المخصص لفحص `SELECT 1` فقط. الحد `DATABASE_POOL_MAX=2`، وحد الاتصالات للدور `3`، أي اتصالين للمسبح واتصال واحد محدود كمساحة هامش. |
| سر API | ملف منفصل `/home/ubuntu/shattab-pg18-stage/secrets/api_password`، منفصل تمامًا عن `postgres_password` الإداري. لا يدخل السر في متغير بيئة أو وسيطات أمر أو Git. |
| تشغيل الحاوية | المستخدم غير الجذر `node`، ونظام ملفات الجذر للقراءة فقط، ومن غير Linux capabilities، مع حدود CPU/RAM/PID وسجلات مدوّرة، وسياسة إعادة تشغيل `no` لأن ده إعداد تجريبي يدوي. |

`depends_on: condition: service_healthy` بيأخر إنشاء خدمة API لحد ما فحص PostgreSQL ينجح. ده ترتيب بداية فقط؛ مش ضمان لتوفر مستمر. فحص `/health/ready` بيختبر اتصال قاعدة البيانات، وفحص `/health/live` بيختبر العملية نفسها.

### 6.2 موافقة وفحص مسبق

نفّذ الخطوات الجاية فقط بعد الموافقة الصريحة على تشغيل قاعدة PostgreSQL 18 التجريبية، إنشاء دور `shattab_api` وملف سره، وبناء وتشغيل حاوية API على Oracle. الموافقة لا تشمل PostgreSQL 17 `shattab-lab` أو Supabase أو فتح منافذ أو نقل بيانات التطبيق.

قبل أي كتابة، افحص حالة `shattab-pg18-stage` من غير تغييرها. لو اسم الـ Compose project أو الصورة أو الشبكة أو الـ volume أو حالة ملفات السيرفر مختلفة عن المتوقع، وقف للمراجعة. لا تقرأ محتوى أي ملف سر. لا تستخدم مجلد `infra/postgres18-stage/secrets/` المحلي للاختبارات؛ اختبارات الكمبيوتر تستخدم مجلدًا مؤقتًا منفصلًا بقيم وهمية.

على Ubuntu SSH (جلسة إدارة آمنة لسيرفر Ubuntu)، ابدأ بفحص إعداد القاعدة الحالي من غير طباعة قيم الأسرار:

```bash
cd /home/ubuntu/shattab-pg18-stage && sudo docker compose --env-file /dev/null --project-directory /home/ubuntu/shattab-pg18-stage -f /root/shattab-pg18-stage-tools/compose.3216004984ca41882f0cc59b6e625e4f88da2f08575e484d7167a5b0c783d008.yaml -p shattab-pg18-stage config --quiet
```

`--quiet` يطلب التحقق من الملف من غير عرضه. لو رجع خطأ، وقف. أداة التحقق الموجودة في `/root/shattab-pg18-stage-tools/verify.py` بتثبت مجلدي المرحلة والأسرار بأوصاف ملفات مفتوحة، وتفحص الملكية والصلاحيات من خلال `fstat`. مساعد السر يفحص غياب `api_password` بالنسبة لوصف مجلد الأسرار المثبّت مباشرة قبل طلب كلمة المرور؛ لو الملف موجود أو الحالة مبهمة، يتوقف من غير استبدال.


### 6.3 نقل ملفات التشغيل بعد الموافقة

مجلد النشر على السيرفر منفصل عن المستودع المحلي. ملف Compose الفعّال هو الـsnapshot المملوك لـ`root` والمحفوظ باسم بصمته في `/root/shattab-pg18-stage-tools/`. احتفظ به كما هو؛ لا تنسخ ملفًا من مجلد `ubuntu` القابل للتعديل فوقه. لو احتجنا إعدادًا أقدم للرجوع، لازم نراجعه ونثبته كـsnapshot جديد باسم بصمته من غير استبدال النسخة الحالية. من `Windows PowerShell` (طرفية ويندوز)، ارفع ملفات الفحص غير السرية فقط إلى مجلد المرحلة:

```powershell
scp .\infra\postgres18-stage\README.md .\infra\postgres18-stage\preflight_api_role.sql .\infra\postgres18-stage\create_api_role.sql ubuntu@<SERVER>:/home/ubuntu/shattab-pg18-stage/
```

ابدأ قاعدة PG18 حسب الأقسام 3 و4 من هذا الدليل، ثم شغّل `sudo python3 /root/shattab-pg18-stage-tools/verify.py`. لازم تنجح أداة التحقق قبل أي إنشاء دور/سر؛ هي بتراجع هوية الحاوية وصورة PostgreSQL والشبكة والـ volume، وبتتحقق من `PGDATA` الفعلي بإعداد `current_setting('data_directory')` أثناء اتصالها بدور `shattab_stage_admin`. في إعداد Compose الحالي، `POSTGRES_USER` بيعمل الدور ده كـ `superuser` (حساب PostgreSQL بصلاحيات كاملة) عند تهيئة قاعدة المرحلة. لا تشغل `infra/postgres-lab` أو أي أداة تخصه.

في اختبار CI، دور `shattab_stage_admin` بيتعمل عمدًا بصلاحية أقل (`LOGIN CREATEROLE`) عشان نختبر فحوص SQL بأقل صلاحيات لازمة. لذلك harness الاختبار (برنامج الاختبار المعزول) بيفحص المسار الفعلي باستعلام قراءة فقط كـ `postgres` superuser داخل الحاوية المقفولة، وبعد تأكيد صحتها وقبل إنشاء أي fixture. ملفات SQL نفسها تراجع هوية قاعدة البيانات والدور والإصدار ومخطط قاعدة البيانات وصلاحيات `PUBLIC`؛ ما بتقرأش `data_directory` أو بتحتاج `pg_read_all_settings`.

بعد نجاح التحقق، شغّل الفحص الإضافي للـ catalog (كتالوج قاعدة البيانات الذي يسجل المخططات والأدوار والصلاحيات). ده فحص قراءة فقط:

```bash
sudo docker compose --env-file /dev/null --project-directory /home/ubuntu/shattab-pg18-stage -f /root/shattab-pg18-stage-tools/compose.3216004984ca41882f0cc59b6e625e4f88da2f08575e484d7167a5b0c783d008.yaml -p shattab-pg18-stage exec -T db psql -X -v ON_ERROR_STOP=1 -U shattab_stage_admin -d shattab_stage -f - < preflight_api_role.sql
```

النتيجة تعرض أعداد المخططات والعلاقات والدوال والأنواع والامتدادات والكائنات الكبيرة، وحالة الدور، وصلاحيات `PUBLIC` (الصلاحيات العامة لكل أدوار PostgreSQL)، وأي `default ACL` (صلاحيات افتراضية تُمنح تلقائيًا للكائنات الجديدة). الفحص يسمح فقط بالافتراضيات القياسية في قاعدة PostgreSQL 18 جديدة: `USAGE` على مخطط `public`، و`CONNECT` و`TEMPORARY` على قاعدة البيانات. لازم كل واحدة تظهر مرة واحدة ومن غير `WITH GRANT OPTION`. أي صلاحية إضافية على المخططات أو كائنات التطبيق أو قاعدة البيانات توقف الإجراء. لازم كمان ما يكونش فيه أي جدول أو دالة أو نوع أو امتداد أو كائن كبير خاص بالتطبيق، ولا أي `default ACL` صريح. في حالة الكائنات الكبيرة، الفحص يقرأ `pg_largeobject_metadata` (كتالوج فيه مالك الكائن وصلاحياته) ويفحص `lomacl` أو الافتراضي من `acldefault('L', lomowner)` عبر `aclexplode`؛ ما بيقرأش بيانات الكائن نفسها. وجود أي كائن كبير أو صلاحية `PUBLIC` عليه يوقف الإجراء. تفاصيل الحقول في [كتالوج PostgreSQL 18 للكائنات الكبيرة](https://www.postgresql.org/docs/18/catalog-pg-largeobject-metadata.html) و[دالة `acldefault` و`aclexplode`](https://www.postgresql.org/docs/18/functions-info.html). ما بتظهرش كلمة سر أو بيانات مستخدمين.

فحص SQL ده بيتأكد من عقد صلاحيات قاعدة البيانات فقط، ومش مسؤول عن `PGDATA` أو مسار الملفات؛ `verify.py` راجعهم بالفعل قبل تشغيله. في CI الاختبار السلوكي بيعيد فحص المسار الفعلي كـ `postgres` superuser في الحاوية المؤقتة قبل أي SQL تعديلي.

الفحص كمان بيعرض إن PostgreSQL القياسي بيدي `EXECUTE` لـ`PUBLIC` على أي دالة جديدة افتراضيًا. ده مش كائن موجود دلوقتي، لكن معناه إن إضافة دوال مستقبلًا ممكن تدي كل الأدوار صلاحية تنفيذها. لذلك أي migration أو إضافة دالة/كائن للتطبيق محتاجة مراجعة منفصلة وإعادة فحص الصلاحيات قبل تشغيل API؛ ما تغيّرش الافتراضيات القياسية تلقائيًا أثناء تجهيز الدور.

### 6.4 إنشاء دور قاعدة البيانات

بعد `PASS` فقط، شغّل ملف إنشاء الدور المحمي بفحوص هوية قاعدة البيانات والإصدار، وغياب الدور وكائنات التطبيق، ومطابقة صلاحيات `PUBLIC` الافتراضية. مسار البيانات اتراجع منفصلًا بواسطة `verify.py` قبل الفحص ده. الملف يفتح معاملة واحدة؛ لو الشروط مش مطابقة، ما يعملش إنشاء. لازم تكون مخرجات الفحص السابق ما زالت حديثة وما حصلش أي تغيير إداري بينها وبين الأمر ده:

```bash
sudo docker compose --env-file /dev/null --project-directory /home/ubuntu/shattab-pg18-stage -f /root/shattab-pg18-stage-tools/compose.3216004984ca41882f0cc59b6e625e4f88da2f08575e484d7167a5b0c783d008.yaml -p shattab-pg18-stage exec -T db psql -X -v ON_ERROR_STOP=1 -U shattab_stage_admin -d shattab_stage -f - < create_api_role.sql
```

الدور `shattab_api` يقدر يسجل دخول، لكنه مش مالك قاعدة أو مخطط أو جدول، ومش `superuser`، وما يقدرش ينشئ قواعد أو أدوار أو يتجاوز `RLS`، وما عندوش عضوية في أدوار تانية. له حد 3 اتصالات، و`search_path=pg_catalog` (ترتيب المخططات اللي PostgreSQL بيدور فيها على الأسماء؛ هنا بيخلي البحث غير المؤهل داخل كتالوج النظام فقط). الدور بياخد افتراضيات `PUBLIC` القياسية اللي كل دور بيستفيد منها تلقائيًا حتى مع `NOINHERIT`: `USAGE` على `public` و`CONNECT` و`TEMPORARY` على قاعدة المرحلة. `TEMPORARY` بيسمح بإنشاء جداول مؤقتة داخل الجلسة؛ الـAPI الحالي ما بيعملش ده، واختيار تعطيله محتاج تغيير سياسة منفصل ومراجَع. دي صلاحيات baseline (الحد الافتراضي المشترك)، مش منحًا إضافيًا من ملف إنشاء الدور. مفيش جدول أو دالة تطبيقية موجودة أو صلاحيات عليها، والـAPI حاليًا بيعمل `SELECT 1` بس. الملف ما يحتويش كلمة سر. بعد نجاح الإنشاء، افتح جلسة `psql` تفاعلية:

```bash
sudo docker compose --env-file /dev/null --project-directory /home/ubuntu/shattab-pg18-stage -f /root/shattab-pg18-stage-tools/compose.3216004984ca41882f0cc59b6e625e4f88da2f08575e484d7167a5b0c783d008.yaml -p shattab-pg18-stage exec -it db psql -X -U shattab_stage_admin -d shattab_stage
```

قبل الأمر، جهّز كلمة سر عشوائية في مدير أسرار (برنامج موثوق لتوليد كلمات السر وحفظها). لازم تكون بترميز `UTF-8` (ترميز موحد للنصوص) وطولها من 32 إلى 4096 بايت، ومن غير محرف `NUL` أو سطر جديد `LF` أو رجوع عربة `CR`. الطول هنا بالبايت بعد الترميز، مش بعدد الحروف. المساعد سيرفض القيمة خارج الشروط دي؛ لو كلمة مرور الدور اتضبطت بالفعل بقيمة أقصر، مش هينشئ ملف السر، وساعتها وقف وارجع غيّر كلمة المرور من جلسة `psql` تفاعلية بدل ما تخفف الشروط.

داخل `psql` نفّذ الأمر ده واكتب السر المجهز مرتين عند المطالبات المخفية؛ `\password` (أمر بيطلب كلمة السر من غير إظهارها وبيحميها من سجل الأوامر ونص SQL) ما يطبعش القيمة. ما تحطش السر في وسيطات أمر (`argv`) أو متغيرات بيئة (`env`) أو نص SQL ظاهر:

```text
\password shattab_api
```

بعد نجاح `\password`، ما تنشئش ملف السر لسه. هنحدد UID/GID (أرقام هوية المستخدم والمجموعة في Linux) من صورة Node المثبتة وننشئ الملف بعد رفع ملفات المرحلة. لاحقًا المساعد هيطلب نفس السر مرتين إضافيتين في إدخال مخفي للمطابقة، من غير `argv` أو `env` أو طباعة.

### 6.5 تجهيز ملفات المرحلة والسر وصورة API

أنشئ مجلد مصدر مستقل وفارغ على السيرفر بعد التأكد إنه مش موجود:

```bash
sudo -u ubuntu mkdir -m 700 /home/ubuntu/shattab-pg18-stage/api-source
```

لو المجلد موجود بالفعل، افحصه ولا تكتب فوقه. من `Windows PowerShell` ارفع ملفات بناء API المحددة إلى هذا المجلد، وليس إلى جذر المستودع أو مجلد الأسرار:

```powershell
scp .\api\Dockerfile .\api\package.json .\api\package-lock.json .\api\tsconfig.json .\api\.dockerignore .\api\src\app.ts .\api\src\config.ts .\api\src\database.ts .\api\src\server.ts ubuntu@<SERVER>:/home/ubuntu/shattab-pg18-stage/api-source/
```

خطوات القسم 2 ترفع `create_api_secret.py` وملف Compose المرشح، وتقارن بصمات الأدوات والـCompose قبل الاستخدام. ملف Compose الموثوق موجود في `/root/shattab-pg18-stage-tools/`؛ ارفع أي نسخة جديدة باسم مرشح مؤقت، ولا تشغّل Compose من `/home/ubuntu`.

لو مراجعة API أنتجت نسخة Compose مختلفة بعد تجهيز الـsnapshot الحالي، خُد بصمتها الجديدة من PowerShell وارفعها باسم مؤقت منفصل بدل استبدال أي نسخة:

```powershell
Get-FileHash .\infra\postgres18-stage\compose.yaml -Algorithm SHA256
scp .\infra\postgres18-stage\compose.yaml ubuntu@<SERVER>:/home/ubuntu/shattab-pg18-stage/compose.<NEW_SHA256>.candidate.yaml
```

استبدل `<NEW_SHA256>` بالبصمة الجديدة بحروف صغيرة. بعد مراجعة التغيير، ثبّت الملف المرشح باسم `/root/shattab-pg18-stage-tools/compose.<NEW_SHA256>.yaml` بوضع `0444` وبمالك `root:root` بشرط أن الاسم غير موجود:

```bash
sudo test ! -e /root/shattab-pg18-stage-tools/compose.<NEW_SHA256>.yaml && sudo test ! -L /root/shattab-pg18-stage-tools/compose.<NEW_SHA256>.yaml && sudo install -o root -g root -m 444 /home/ubuntu/shattab-pg18-stage/compose.<NEW_SHA256>.candidate.yaml /root/shattab-pg18-stage-tools/compose.<NEW_SHA256>.yaml && sudo stat -c '%a %u:%g %n' /root/shattab-pg18-stage-tools/compose.<NEW_SHA256>.yaml && sudo sha256sum /root/shattab-pg18-stage-tools/compose.<NEW_SHA256>.yaml
```

قارن بصمة `sha256sum` بالبصمة المحلية قبل أي استخدام. لو الملف موجود، افحص النوع والمالك والوضع والبصمة وأعد استخدامه فقط لو كلها مطابقة؛ غير كده وقف. بعد المراجعة وتثبيت الملف الجديد، غيّر ثابت `COMPOSE_FILE` في نسخة `verify.py` الجديدة وكل قيم `-f` في الدليل للبصمة الجديدة. ثبّت نسخة verifier الجديدة في اسم root-only جديد بعد مقارنة بصمتها، وسيب الـsnapshot والـverifier القديمين زي ما هم.

أولًا افحص UID/GID من صورة Node الأساسية المثبتة بنفس `digest` (بصمة محتوى ثابتة) الموجودة في Dockerfile. الأمر ده قد ينزّل الصورة لو مش موجودة محليًا، لكنه ما يشغّلش خدمة دائمة ولا يفتح منفذ:

```bash
sudo docker run --rm --entrypoint id node:24.22.1-bookworm-slim@sha256:55fb5f5a527ea2c5c4a95f963e48ef90aa38c7b346054fdc8ee9957a2b55d205 node
```

اقرأ من النتيجة رقم `uid` ورقم `gid` للمستخدم `node`. لازم `uid` يكون غير صفر. ما تفترضش إن الأرقام `1000:1000`؛ استخدم القيم اللي ظهرت فعلًا.

خطوات الـbootstrap في القسم 2 تنشئ مجلد الأسرار لو مش موجود وتتحقق إن وضعه `0700` وملكيته `root`. لا تصلّح المسارات يدويًا باستخدام `chown` أو `chmod`؛ عند أي اختلاف، وقف للمراجعة. `Docker daemon` (خدمة Docker اللي بتشغّل الحاويات بصلاحية النظام) يقرأ الملف عند تشغيل Compose بـ`sudo`.

المساعد المثبّت في `/root/shattab-pg18-stage-tools/create_api_secret.py` يثبت مجلد المرحلة ومجلد الأسرار بأوصاف ملفات مفتوحة ويفحصهما عبر `fstat`. قبل طلب السر، يفحص غياب الملف باستخدام `dir_fd` (مرجع لمجلد مفتوح)؛ أي ملف أو رابط موجود يوقف العملية من غير `overwrite` (كتابة فوق الموجود). `getpass` (إدخال تفاعلي ما بيعرضش الأحرف) يطلب السر مرتين للمطابقة، والمساعد يرفض الطرفية غير التفاعلية أو طول/ترميز/محارف غير مسموحة، يكتب ملفًا مؤقتًا بصلاحية خاصة، ثم ينشره نسبةً لوصف المجلد المثبّت ومن غير استبدال ملف موجود. لو فشل حذف الملف المؤقت، هيرجع خطأ واضح إن السر قد يكون نُشر وإن ملفًا مؤقتًا ممكن يفضل؛ افحص الحالة يدويًا قبل أي إعادة محاولة. الأخطاء لا تطبع قيمة السر:

```bash
sudo python3 /root/shattab-pg18-stage-tools/create_api_secret.py --node-uid 1000 --node-gid 1000
```

الأرقام في مثال المساعد مجرد مثال؛ استبدلها بالـ UID/GID اللذين أظهرهما أمر `id` قبل التنفيذ. المساعد ينشئ `/home/ubuntu/shattab-pg18-stage/secrets/api_password` بمالك `root` ومجموعة GID الخاصة بـ`node`، يعني `root:<process-gid>`، ووضع `0440` (قراءة للمالك والمجموعة فقط). لا يغير ملفات الأسرار الموجودة. المساعد يراجع metadata (بيانات النوع والملكية والصلاحيات) على الأوصاف المثبّتة من غير قراءة محتوى السر أو عرضه.

المتوقع `700` للمجلدين و`440 0:<GID>` لملف السر، حيث `<GID>` هو نفس الرقم المتحقق منه. لو فشل المساعد أو ظهر ملف جزئي/موجود، سيب الحالة زي ما هي ووقف للمراجعة؛ ما تمسحش الملف وما تعيدش إنشاءه تلقائيًا. الملف مش مشفر على قرص السيرفر؛ مدير السيرفر وDocker يقدروا يقرؤوه.

بعد وجود السر، افحص إعداد Compose بصمت. لازم نجاحه من غير output؛ أي خطأ يوقف البناء:

```bash
cd /home/ubuntu/shattab-pg18-stage && sudo docker compose --env-file /dev/null --project-directory /home/ubuntu/shattab-pg18-stage -f /root/shattab-pg18-stage-tools/compose.3216004984ca41882f0cc59b6e625e4f88da2f08575e484d7167a5b0c783d008.yaml -p shattab-pg18-stage config --quiet
```

ابنِ صورة API على السيرفر باستخدام Dockerfile متعدد المراحل (يبني التطبيق ثم ينسخ ملفات التشغيل اللازمة فقط للصورة النهائية):

```bash
sudo docker compose --env-file /dev/null --project-directory /home/ubuntu/shattab-pg18-stage -f /root/shattab-pg18-stage-tools/compose.3216004984ca41882f0cc59b6e625e4f88da2f08575e484d7167a5b0c783d008.yaml -p shattab-pg18-stage build api
```

البناء يحتاج اتصالًا لتنزيل صور Node/حزم npm وقد يستهلك مساحة وبيانات نقل. لا يفتح منفذًا ولا ينشئ جداول. بعد البناء، أعد فحص UID/GID للمستخدم داخل صورة API المكتملة:

```bash
sudo docker run --rm --entrypoint id shattab-api:stage node
```

لازم UID/GID يطابقوا القيم اللي تحققت منها في صورة Node الأساسية قبل إنشاء السر. لو اختلفوا، ما تشغّلش الخدمة وما توسعش الصلاحيات؛ أوقف وراجع سبب اختلاف الصورة أو البناء.

بعد تطابق الهوية، شغّل API فقط:

```bash
sudo docker compose --env-file /dev/null --project-directory /home/ubuntu/shattab-pg18-stage -f /root/shattab-pg18-stage-tools/compose.3216004984ca41882f0cc59b6e625e4f88da2f08575e484d7167a5b0c783d008.yaml -p shattab-pg18-stage up -d api
```

`up -d api` يربط API بالشبكة الداخلية ويستخدم `depends_on` للتأكد إن قاعدة البيانات `healthy`. مفيش `ports` في الخدمة؛ عنوان `0.0.0.0:3000` جوه الحاوية مش ظاهر مباشرة من الإنترنت.

### 6.6 تحقق من الحالة والصلاحيات والتراجع

اعرض حالتي الخدمتين:

```bash
sudo docker compose --env-file /dev/null --project-directory /home/ubuntu/shattab-pg18-stage -f /root/shattab-pg18-stage-tools/compose.3216004984ca41882f0cc59b6e625e4f88da2f08575e484d7167a5b0c783d008.yaml -p shattab-pg18-stage ps
```

المتوقع `db` و`api` بالحالة `healthy`. ده دليل اتصال قاعدة البيانات وفحص `SELECT 1` فقط. افحص بيانات تركيب الملف ومستخدم العملية من غير قراءة محتواه:

```bash
sudo docker inspect --format '{{range .Mounts}}{{if eq .Destination "/run/secrets/api_password"}}type={{.Type}} rw={{.RW}} source={{.Source}}{{end}}{{end}}' "$(sudo docker compose --env-file /dev/null --project-directory /home/ubuntu/shattab-pg18-stage -f /root/shattab-pg18-stage-tools/compose.3216004984ca41882f0cc59b6e625e4f88da2f08575e484d7167a5b0c783d008.yaml -p shattab-pg18-stage ps -q api)"
```

المتوقع `type=bind rw=false` والمصدر هو ملف `api_password` المخصص. افحص إن مالك الملف `root`، ومجموعته هي الـGID الأساسي للعملية، والصلاحية بالضبط `0440` (قراءة للمالك والمجموعة فقط من غير أي كتابة أو صلاحيات للآخرين)، وإن UID وEUID للعملية مش صفر؛ `EUID` (معرّف المستخدم الفعّال في Linux) هو اللي بيحدد صلاحيات العملية وقت التنفيذ. الكود كمان بيفتح الملف للقراءة وبيقرأ بايت من غير عرضه، وبيحاول يفتحه للكتابة من غير `O_TRUNC` (خيار بيمسح محتوى الملف عند الفتح) عشان يثبت إن الكتابة مرفوضة من غير تغيير الملف. بيعرض UID/GID والصلاحية بس:

```bash
sudo docker compose --env-file /dev/null --project-directory /home/ubuntu/shattab-pg18-stage -f /root/shattab-pg18-stage-tools/compose.3216004984ca41882f0cc59b6e625e4f88da2f08575e484d7167a5b0c783d008.yaml -p shattab-pg18-stage exec -T api node -e 'const fs=require("node:fs");const p="/run/secrets/api_password";const s=fs.lstatSync(p);const m=s.mode&0o777;const uid=process.getuid(),euid=process.geteuid(),gid=process.getgid();if(!s.isFile()||s.uid!==0||uid===0||euid===0||s.gid!==gid||m!==0o440)process.exit(1);const r=fs.openSync(p,fs.constants.O_RDONLY|fs.constants.O_NOFOLLOW);const b=Buffer.alloc(1);if(fs.readSync(r,b,0,1,0)!==1)process.exit(1);fs.closeSync(r);let denied=false;try{const w=fs.openSync(p,fs.constants.O_WRONLY|fs.constants.O_NOFOLLOW|fs.constants.O_NONBLOCK);fs.closeSync(w)}catch(e){denied=["EACCES","EPERM","EROFS"].includes(e.code)}if(!denied)process.exit(1);console.log(`PASS uid=${uid} euid=${euid} gid=${gid} file_gid=${s.gid} mode=${m.toString(8)} readable=true writable=false`);'
```

لازم `uid` مش صفر، و`readable=true` و`writable=false`. فشل أي تحقق يوقف العملية؛ لا توسع صلاحيات الملف. راجع `docker inspect` للتأكد إن mount (تركيب الملف داخل الحاوية) للقراءة فقط. بعد النجاح، أوقف API وحدها لو عايز تحافظ على موارد التجربة:

```bash
sudo docker compose --env-file /dev/null --project-directory /home/ubuntu/shattab-pg18-stage -f /root/shattab-pg18-stage-tools/compose.3216004984ca41882f0cc59b6e625e4f88da2f08575e484d7167a5b0c783d008.yaml -p shattab-pg18-stage stop api
```

لإيقاف تكامل API، استخدم الأمر السابق `stop api`. ده بيوقف حاوية API فقط؛ ملف Compose الجاري يفضل snapshot الحالي المحمي، وقاعدة PG18 والـvolume والسرين يفضلوا للتحقيق. ما تنسخش `compose.yaml.pre-api` أو أي ملف من مجلد `ubuntu` وتعتبره الإعداد الفعّال، لأن كل أوامر Compose بتقرأ الـsnapshot الموجود تحت `/root`.

لو مطلوب الرجوع لتعريف Compose أقدم، راجع النسخة الأقدم أولًا وثبّتها كملف جديد تحت `/root/shattab-pg18-stage-tools/compose.<OLD_SHA256>.yaml` بمالك `root:root` وصلاحية `0444`، بشرط عدم وجود الاسم، ثم تحقق من بصمتها. احتفظ بالـsnapshot الحالي. قبل أي استخدام للنسخة الأقدم، حدّث نسخة `verify.py` والدليل بحيث يشيرا إلى اسمها الفعلي المشتق من البصمة المراجعة، ثم شغّل `config --quiet` و`ps` باستخدام مسار snapshot الأقدم المحمي، مع `--project-directory /home/ubuntu/shattab-pg18-stage` و`-p shattab-pg18-stage`. ما تنفذش أوامر بوسم placeholder زي `<OLD_SHA256>`، وما تعتبرش ملفًا من مجلد `ubuntu` إعدادًا فعالًا. بعد التحقق، راجع إن `ps` يعرض الخدمات المتوقعة من النسخة القديمة. ما تستخدمش `down -v`، أو `volume rm`، أوامر حذف، أو أي تعديل على `shattab-lab`. تغيير تعريف Compose لا يحذف الدور أو ملف السر؛ احتفظ بيهم لحد ما تتراجع خطة إزالة معتمدة.

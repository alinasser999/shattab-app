# PostgreSQL 18 staging على Oracle

دي قاعدة PostgreSQL (قاعدة بيانات علائقية) فاضية للتجارب المرحلية على سيرفر Oracle. مش قاعدة إنتاج، ومفيش بيانات أو migrations (ملفات تغييرات مخطط قاعدة البيانات) أو مستخدمين من Supabase اتنقلوا لها. تشغيلها ما معناهش إن تطبيق شطب اتنشر.

## الحالة المؤكدة على Oracle — فحص 2026-10-27

القائمة دي بتلخّص آخر حالة اتأكدنا منها مباشرة على السيرفر؛ هي مش ضمان إن الحالة ما اتغيرتش بعد الفحص. قبل أي خطوة جديدة، اعمل الفحوصات المذكورة في القسم المناسب:

- قاعدة PostgreSQL 18 التجريبية وقاعدة المختبر PostgreSQL 17 كانتا `healthy` وقت الفحص.
- ملفات مصدر الـAPI العشرة المسموح بها اترفعت بعد مقارنة بصمات `SHA-256` (بصمة رقمية لمحتوى الملف)، واتحفظ المصدر السابق باسم منفصل.
- ملف `Docker Compose` (تعريف الخدمات والشبكات والتخزين) الفعّال محفوظ كنسخة ثابتة مملوكة لـ`root` بصلاحية قراءة فقط `0444`، وفحص `config --quiet` نجح.
- صورة `shattab-api:stage` اتبنت لمعمارية `ARM64`، ومستخدم التشغيل `node` اتأكد إنه غير `root` بهوية `UID/GID 1000:1000`. وسم الرجوع `shattab-api:stage-prev-20261026` موجود وبصمته `sha256:369a05cb4df7d37d9b87a7a036ac65e466cea2fc51c6e66b0b90bb580cef387c` حسب فحص metadata للقراءة فقط بتاريخ 2026-10-27.
- في فحص 2026-10-27، حاوية الـAPI كانت `running` و`healthy`، و`GET /health/live` و`GET /health/ready` رجعوا `200`. فحص الجاهزية اتصل بقاعدة `shattab_stage` بدور `shattab_api`، وظهر اتصال واحد بحالة `idle`.
- ملف السر موجود على السيرفر في `/root/shattab-pg18-stage-tools/secrets/api_password` بمالك `root` ومجموعة `1000` ووضع `0440`. القيمة اتولدت داخل السيرفر وما اتعرضتش. داخل الحاوية اتركّب على `/run/secrets/api_password` للقراءة فقط، والـAPI تعمل بهوية `node` ونظام ملفات جذر للقراءة فقط.
- فحص الحاوية أكد إن منفذ API `3000` مش منشور على المضيف. قاعدة المرحلة ما زالت بلا migrations أو بيانات تطبيق. لم تتغير قواعد OCI أو Supabase أو موارد الإنتاج؛ قابلية الوصول من الإنترنت وقواعد OCI الفعلية لم تُفحص في هذه الخطوة.

دي مرحلة تشغيل واختبار داخلية فقط؛ الـAPI لسه health-only (بتفحص حياة الخدمة واتصال قاعدة البيانات) ومش فيها وظائف شطب أو ربط مع تطبيق Flutter ولوحة الإدارة.

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

الخطوات دي بتشرح التأسيس الأولي. بما إن مجلد المرحلة وقاعدة البيانات وملف Compose المحمي موجودين بالفعل في الحالة المؤكدة أعلاه، ما تعيدش أوامر الإنشاء اللي بتشترط إن المسارات تكون غايبة. ابدأ بفحص الحالة الحالية، وبعدها كمّل من القسم 6.3؛ أي اختلاف يوقف التنفيذ للمراجعة.

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

## 6. تكامل API تجريبي — شغّال داخليًا على مرحلة Oracle

القسم ده يشرح التكامل الداخلي التجريبي لخدمة API (واجهة خدمات بتستقبل طلبات التطبيقات) الموجودة في `api/` مع قاعدة PostgreSQL 18. المصدر اتنقل واتعملت الصورة على Oracle، والحاوية شغالة حاليًا على شبكة Docker داخلية. الـAPI health-only (وظيفتها الحالية فحص إن العملية وقاعدة البيانات شغالين) وبتشغّل استعلامًا ثابتًا `SELECT 1`. مفيش جداول شطب أو بيانات مستخدمين أو ميزات تطبيقية في النطاق ده، ومش بديل لـSupabase.

**الحالة المؤكدة بتاريخ 2026-10-27:** دور `shattab_api` اتراجع قبل تغيير كلمة مروره، ثم اتضبطت له كلمة مرور عشوائية من غير عرضها. ملف السر اتعمل بصلاحية `0440` واتنقل ذريًا إلى المسار اللي إعداد Compose الفعّال بيشير له، من غير قراءة محتواه أو استبدال ملف موجود. الحاوية بقت `healthy`، وفحصا الحياة والجاهزية رجعوا `200`، وظهر اتصال واحد من `shattab_api` بقاعدة المرحلة. ما تعيدش إنشاء الملف أو تغيير كلمة المرور لمجرد إعادة تشغيل الحاوية؛ أعد الفحوصات فقط قبل أي تغيير جديد.

### 6.1 شكل الاتصال وحدوده

| الإعداد | القيمة والخبرة المطلوبة |
| --- | --- |
| مصدر البناء | ملفات API غير السرية فقط في `/home/ubuntu/shattab-pg18-stage/api-source/`. ملف Compose الموثوق موجود تحت `/root/shattab-pg18-stage-tools/`، و`--project-directory /home/ubuntu/shattab-pg18-stage` يثبت حل المسار النسبي `./api-source` داخل مجلد المرحلة. |
| شبكة API | شبكة Docker داخلية `shattab-pg18-stage_db_internal` فقط؛ اسم خدمة قاعدة البيانات داخل الشبكة `db`. |
| المنفذ | API يستمع على `3000` داخل شبكة الحاويات فقط. مفيش `ports` في Compose؛ بالتالي لا يوجد نشر لمنفذ API أو PostgreSQL على السيرفر. |
| اتصال قاعدة البيانات | قاعدة `shattab_stage` ودور `shattab_api` المخصص لفحص `SELECT 1` فقط. الحد `DATABASE_POOL_MAX=2`، وحد الاتصالات للدور `3`، أي اتصالين للمسبح واتصال واحد محدود كمساحة هامش. |
| سر API | ملف منفصل `/root/shattab-pg18-stage-tools/secrets/api_password`، منفصل تمامًا عن `postgres_password` الإداري، ويركب داخل الحاوية على `/run/secrets/api_password` للقراءة فقط. لا يدخل السر في متغير بيئة أو وسيطات أمر أو Git. |
| تشغيل الحاوية | المستخدم غير الجذر `node`، ونظام ملفات الجذر للقراءة فقط، ومن غير Linux capabilities، مع حدود CPU/RAM/PID وسجلات مدوّرة، وسياسة إعادة تشغيل `no` لأن ده إعداد تجريبي يدوي. |

`depends_on: condition: service_healthy` بيأخر إنشاء خدمة API لحد ما فحص PostgreSQL ينجح. ده ترتيب بداية فقط؛ مش ضمان لتوفر مستمر. فحص `/health/ready` بيختبر اتصال قاعدة البيانات، وفحص `/health/live` بيختبر العملية نفسها.

### 6.2 موافقة وفحص مسبق

دور `shattab_api` موجود بالفعل في قاعدة المرحلة حسب لقطة القراءة فقط بتاريخ `2026-10-27`؛ المسار هنا **لا ينشئ دورًا** ولا يغيّر صلاحياته أو إعداداته. التفويض الخاص بتشغيل المرحلة يسمح فقط، بعد اجتياز كل البوابات، بتغيير كلمة مرور هذا الدور يدويًا، وإنشاء ملف سره، وتشغيل خدمة `api` وحدها. لا يشمل `shattab-lab` أو Supabase أو الإنتاج أو تغييرات الشبكة أو ترحيل بيانات.

قبل أي كتابة، افحص حالة المشروع والقاعدة من غير طباعة قيم الأسرار. لو هوية المشروع أو الصورة أو الشبكة أو الـvolume أو حالة الملفات مختلفة عن المتوقع، توقّف للمراجعة. لا تقرأ محتوى أي ملف سر، ولا تستخدم مجلد `infra/postgres18-stage/secrets/` المحلي للاختبارات؛ الاختبارات تستخدم مجلدًا مؤقتًا منفصلًا بقيم وهمية.

على Ubuntu SSH (جلسة إدارة آمنة لسيرفر Ubuntu)، تحقق بصمت من ملف Compose:

```bash
cd /home/ubuntu/shattab-pg18-stage && sudo docker compose --env-file /dev/null --project-directory /home/ubuntu/shattab-pg18-stage -f /root/shattab-pg18-stage-tools/compose.3216004984ca41882f0cc59b6e625e4f88da2f08575e484d7167a5b0c783d008.yaml -p shattab-pg18-stage config --quiet
```

`--quiet` (تحقق من الإعداد من غير عرضه) لازم ينتهي بنجاح ومن غير output؛ أي خطأ يوقف الخطوات. بعده شغّل فاحص المرحلة:

```bash
sudo python3 /root/shattab-pg18-stage-tools/verify.py
```

الفاحص يتحقق من هوية حاوية PostgreSQL وصورتها وشبكتها والـvolume، ويقرأ `current_setting('data_directory')` كـ`shattab_stage_admin` الذي أنشأه Compose كـ`superuser` (دور PostgreSQL بصلاحيات كاملة). في اختبار CI يُجرى فحص `PGDATA` باستعلام قراءة فقط منفصل كـ`postgres` داخل الحاوية المعزولة قبل إنشاء fixtures؛ ملف SQL التالي نفسه لا يقرأ `data_directory` ولا يحتاج `pg_read_all_settings`. لا تستخدم `infra/postgres-lab` أو أي أداة تخصه.

### 6.3 نقل ملفات الفحص والتحقق من الدور الموجود

ملفات الخادم منفصلة عن المستودع. الـCompose الفعّال هو snapshot محمي مملوك لـ`root` تحت `/root/shattab-pg18-stage-tools/`؛ احتفظ به كما هو، ولا تشغّل Compose من مجلد `ubuntu`. من `Windows PowerShell` (طرفية ويندوز)، احسب بصمة ملف الاستعلام وارفعه باسم مرشح فريد؛ لو الاسم موجود، لا تستبدله، وافحص بصمته وأعد استخدامه فقط لو مطابقة:

```powershell
Get-FileHash .\infra\postgres18-stage\inspect_existing_api_role.sql -Algorithm SHA256
ssh ubuntu@<SERVER> 'test ! -e /home/ubuntu/shattab-pg18-stage/inspect_existing_api_role.candidate-c7f3f2024c75c13c52217e7b233a668f42f7e34d.sql && test ! -L /home/ubuntu/shattab-pg18-stage/inspect_existing_api_role.candidate-c7f3f2024c75c13c52217e7b233a668f42f7e34d.sql'
if ($LASTEXITCODE -ne 0) { throw 'Candidate exists; inspect it without overwriting.' }
scp .\infra\postgres18-stage\inspect_existing_api_role.sql ubuntu@<SERVER>:/home/ubuntu/shattab-pg18-stage/inspect_existing_api_role.candidate-c7f3f2024c75c13c52217e7b233a668f42f7e34d.sql
```

على السيرفر، قارن `sha256sum` بالبصمة المحلية قبل تشغيل الاستعلام. لا ترفع `preflight_api_role.sql` أو `create_api_role.sql` لهذا المسار؛ الاتنين معمولين لحالة غياب الدور. استخدم فاحص المرحلة مرة تانية، ثم نفّذ الاستعلام الجديد:

```bash
sudo sha256sum /home/ubuntu/shattab-pg18-stage/inspect_existing_api_role.candidate-c7f3f2024c75c13c52217e7b233a668f42f7e34d.sql
```

بعد تطابق البصمة، نفّذ فاحص المرحلة مرة أخرى. الاستعلام الجديد له مستويان: كل تشغيل يراجع ACL/المالك/`CONNECT`/`TEMPORARY`/`CREATE` على مستوى الـcluster لكل صف في `pg_database`، بما فيها `template1` و`template0`؛ ثم يراجع المخططات والكائنات و`pg_default_acl` محليًا في قاعدة الاتصال الحالية. لازم تكون `shattab_stage` مملوكة لـ`shattab_stage_admin`. baseline `PUBLIC CONNECT` متوقع على كل قواعد cluster، بما فيها القوالب. أما `PUBLIC TEMPORARY` فمتوقع على القواعد العادية فقط؛ PostgreSQL 18 `initdb` (أداة التأسيس الأولي للكلستر) يسحب `CREATE` و`TEMPORARY` من `PUBLIC` على `template0` و`template1`. بالتالي دور API ما يكونش عنده `TEMPORARY` فعّال على القواعد القالبية، بينما القواعد العادية تحتفظ بالـbaseline. لازم `template1` تكون قاعدة قالبية وقابلة للاتصال، و`template0` تكون قاعدة قالبية ومغلقة (`datallowconn=false`). ممنوع محاولة الاتصال بـ`template0`.

على Ubuntu SSH، احتفظ بنفس جلسة Bash مفتوحة من بداية الفحص لحد بوابة كلمة المرور؛ متغيرات اللقطة `DB_SNAPSHOT_INITIAL` و`COMPOSE` مستخدمة تاني قبل كتابة كلمة المرور. لو الجلسة انتهت، أعد الحلقة كلها من البداية، وما تعتمدش على لقطة قديمة. خُد inventory snapshot (لقطة جرد) لكل قاعدة، بالاسم وحالتي `datallowconn` و`datistemplate`، ثم تحقق إن `template0` موجودة ومغلقة كقاعدة قالبية، و`template1` موجودة وقابلة للاتصال كقاعدة قالبية، ومافيش قاعدة أخرى مغلقة. الحلقة تشغّل الاستعلام المحلي على **كل** قاعدة `datallowconn=true`، بما فيها `template1` حتى لو `datistemplate=true`؛ بتتخطى `template0` المقفولة من غير ما تتصل بها. أي اسم غير آمن، أو قاعدة قابلة للاتصال لا يمكن فحصها، أو فشل في أي استعلام يوقف الخطوات:

```bash
set -euo pipefail
COMPOSE=(sudo docker compose --env-file /dev/null --project-directory /home/ubuntu/shattab-pg18-stage -f /root/shattab-pg18-stage-tools/compose.3216004984ca41882f0cc59b6e625e4f88da2f08575e484d7167a5b0c783d008.yaml -p shattab-pg18-stage)
DB_INVENTORY_SQL="SELECT datname || '|' || datallowconn::text || '|' || datistemplate::text FROM pg_database ORDER BY datname;"
validate_database_inventory() {
  local snapshot="$1"
  printf '%s\n' "$snapshot" | awk -F '|' '
    NF != 3 || $1 !~ /^[A-Za-z_][A-Za-z0-9_]*$/ || ($2 != "true" && $2 != "false") || ($3 != "true" && $3 != "false") { exit 1 }
    $1 == "template0" { if ($2 != "false" || $3 != "true") exit 1; template0++ }
    $1 == "template1" { if ($2 != "true" || $3 != "true") exit 1; template1++ }
    $2 == "false" && $1 != "template0" { exit 1 }
    END { if (template0 != 1 || template1 != 1) exit 1 }
  '
}
run_catalog_guard_for_snapshot() {
  local snapshot="$1"
  local db_name allow_connections is_template
  while IFS='|' read -r db_name allow_connections is_template; do
    case "$db_name" in ''|[0-9]*|*[!A-Za-z0-9_]*) printf 'FAIL: unsafe database name; stop.\n' >&2; exit 1 ;; esac
    if [ "$allow_connections" != "true" ]; then
      test "$db_name" = "template0" && test "$is_template" = "true" || { printf 'FAIL: unexpected closed database; stop.\n' >&2; exit 1; }
      continue
    fi
    printf 'Inspecting PG18 database: %s\n' "$db_name"
    "${COMPOSE[@]}" exec -T db psql -X -v ON_ERROR_STOP=1 -U shattab_stage_admin -d "$db_name" -f - < /home/ubuntu/shattab-pg18-stage/inspect_existing_api_role.candidate-c7f3f2024c75c13c52217e7b233a668f42f7e34d.sql || return 1
  done <<< "$snapshot"
}
DB_SNAPSHOT_INITIAL=$("${COMPOSE[@]}" exec -T db psql -X -A -t -v ON_ERROR_STOP=1 -U shattab_stage_admin -d postgres -c "$DB_INVENTORY_SQL")
test -n "$DB_SNAPSHOT_INITIAL"
validate_database_inventory "$DB_SNAPSHOT_INITIAL" || { printf 'FAIL: invalid PostgreSQL database inventory; stop.\n' >&2; exit 1; }
run_catalog_guard_for_snapshot "$DB_SNAPSHOT_INITIAL" || { printf 'FAIL: a database catalog guard failed; stop.\n' >&2; exit 1; }
DB_SNAPSHOT_AFTER=$("${COMPOSE[@]}" exec -T db psql -X -A -t -v ON_ERROR_STOP=1 -U shattab_stage_admin -d postgres -c "$DB_INVENTORY_SQL")
test "$DB_SNAPSHOT_AFTER" = "$DB_SNAPSHOT_INITIAL" || { printf 'FAIL: PostgreSQL database inventory changed during inspection; restart the full guard.\n' >&2; exit 1; }
```

لا تعتبر `PASS` من قاعدة واحدة نجاحًا للـcluster؛ لازم كل قاعدة ظاهرة في اللقطة وقابلة للاتصال ترجع `PASS`، ولقطة ما بعد الحلقة تطابق لقطة البداية حرفيًا. ده يشمل `template1`، بينما `template0` تظهر في الجرد لكن لا نتصل بها. أي اتصال فاشل أو اسم غير آمن أو اختلاف في الجرد يوقف البوابة بالكامل. قاعدة `shattab-lab` على PostgreSQL 17 خادم منفصل، مش هتظهر في تعداد خدمة PG18 دي، وما تتصلش بها أو تفحصها ضمن الخطوة.

المخرجات تعرض counts ونتائج تحقق آمنة فقط. `PASS` شرط لازم قبل أي تغيير كلمة مرور أو إنشاء ملف سر أو بدء API. `FAIL` أو خطأ في الاستعلام يعني التوقف؛ لا تصلح الاختلاف بإضافة `GRANT` أو `REVOKE` أو `ALTER ROLE` ولا تشغّل ملف إنشاء الدور. لا تنه أي جلسة نشطة. أي اختلاف إداري بين الفحص والخطوة التالية يعيد البوابة من البداية.

في تشغيل CI رقم `10`، نجح job عقد API، لكن تشغيل CI العام فشل في بوابات أخرى؛ ده مش نجاح كامل للـCI ولا دليل على حالة Oracle الحية.

### 6.4 بوابة شروط السر قبل أي كتابة — اجتازت للمرحلة الحالية

الفحص السابق للتغيير أكد إن الملف المستهدف غير موجود، وإن دور `shattab_api` موجود ومحدود الصلاحيات ولا يملك كلمة مرور. بعد الموافقة المحددة لتجهيز مرحلة الاختبار، اتولدت كلمة المرور على السيرفر، واتضبطت باستخدام `psql \password` من خلال إدخال مخفي، ثم اتعمل ملف السر. الحالة الحالية مختلفة عن شرط البداية: الملف موجود في `/root/shattab-pg18-stage-tools/secrets/api_password`، لذلك لا تشغّل فحوص `test ! -e` الخاصة بالتهيئة الأولى ولا تعاود تغيير كلمة المرور أو إنشاء الملف. افحص الملكية والصلاحيات من غير قراءة المحتوى قبل أي خطوة تشغيل جديدة.

الملف الحالي مملوك لـ`root:1000` وصلاحيته `0440`، ومجلد الأسرار مملوك لـ`root` وصلاحيته `0700`. داخل الحاوية، تركيب الملف `rw=false`؛ الـAPI تقرأه من `/run/secrets/api_password`. الملف مش مشفر على قرص السيرفر؛ مدير النظام وDocker يقدروا يقرؤوه. أي تدوير لاحق للسر يحتاج خطة متزامنة لتغيير كلمة مرور الدور والملف، وموافقة منفصلة قبل التنفيذ.

لو هتجهز بيئة جديدة مستقبلًا، فدي متطلبات التهيئة الأولى فقط: لازم تتأكد إن `psql \\password` بيشتغل من خلال TTY (طرفية تفاعلية) وبيخفي الإدخال. كلمة المرور لازم تكون بترميز `UTF-8` وطول من 32 إلى 4096 بايت، ومن غير `NUL` أو سطر جديد `LF` أو رجوع عربة `CR`، وما تتحطش في `argv` (وسائط سطر الأوامر) أو `env` (متغيرات البيئة). المتطلبات دي لا تعني إنك تعيد ضبط السر الموجود في المرحلة الحالية.

### 6.5 تجهيز ملفات المرحلة والسر وصورة API — الإجراء الحالي اكتمل

الإجراء التالي هو سجل مرجعي لكيفية تجهيز نسخة مرحلية جديدة، وليس أمرًا بإعادة التنفيذ على الحالة الحالية. الصورة والحاوية والسر موجودون بالفعل؛ لا تعاود تشغيل خطوات تغيير كلمة المرور أو إنشاء الملف. المسار الفعلي للسر في هذه النسخة هو `/root/shattab-pg18-stage-tools/secrets/api_password` لأن الأداة المثبتة وملف Compose موجودان تحت `/root/shattab-pg18-stage-tools/`.

ارفع مصدر البناء من الـworktree المراجع فقط، وليس من الـcheckout الأساسي المتسخ أو من مجلد المشروع كله. قبل النقل من `Windows PowerShell`، تحقق من الرأس ومن عدم وجود تغييرات على ملفات API المتتبعة:

```powershell
$apiSourceCommit = '483360250627e4fc99a9cd519582e3b7b948fae9'; git merge-base --is-ancestor $apiSourceCommit HEAD; if ($LASTEXITCODE -ne 0) { throw 'API source baseline is not an ancestor of HEAD; stop.' }; git diff --quiet $apiSourceCommit -- api; if ($LASTEXITCODE -ne 0) { throw 'Tracked API source differs from its reviewed baseline; stop.' }
```

لا تنقل أي ملف غير موجود في القائمة التالية؛ `graphify-out/` ملف محلي غير تابع لمصدر التطبيق ولا يُنقل.

احسب بصمات الملفات محليًا:

```powershell
$apiFiles = @('.\api\Dockerfile', '.\api\package.json', '.\api\package-lock.json', '.\api\tsconfig.json', '.\api\.dockerignore', '.\api\src\app.ts', '.\api\src\config.ts', '.\api\src\database.ts', '.\api\src\server.ts', '.\api\src\auth\cognito.ts'); Get-FileHash -Algorithm SHA256 -Path $apiFiles | Select-Object Hash, Path
```

مجلد `api-source` الموجود من التشغيل السابق لا نكتب فوقه. أنشئ مجلد مرشح جديد بالاسم المرتبط بالـcommit، فقط إذا كان الاسم غير موجود:

```bash
sudo test ! -e /home/ubuntu/shattab-pg18-stage/api-source.candidate-483360250627e4fc99a9cd519582e3b7b948fae9 && sudo test ! -L /home/ubuntu/shattab-pg18-stage/api-source.candidate-483360250627e4fc99a9cd519582e3b7b948fae9 && sudo -u ubuntu mkdir -m 700 /home/ubuntu/shattab-pg18-stage/api-source.candidate-483360250627e4fc99a9cd519582e3b7b948fae9 && sudo -u ubuntu mkdir -m 700 /home/ubuntu/shattab-pg18-stage/api-source.candidate-483360250627e4fc99a9cd519582e3b7b948fae9/src && sudo -u ubuntu mkdir -m 700 /home/ubuntu/shattab-pg18-stage/api-source.candidate-483360250627e4fc99a9cd519582e3b7b948fae9/src/auth
```

من جذر الـworktree نفسه، ارفع allowlist (قائمة الملفات المسموح نقلها) فقط إلى المجلد المرشح:

```powershell
scp .\api\Dockerfile .\api\package.json .\api\package-lock.json .\api\tsconfig.json .\api\.dockerignore ubuntu@<SERVER>:/home/ubuntu/shattab-pg18-stage/api-source.candidate-483360250627e4fc99a9cd519582e3b7b948fae9/
scp .\api\src\app.ts .\api\src\config.ts .\api\src\database.ts .\api\src\server.ts ubuntu@<SERVER>:/home/ubuntu/shattab-pg18-stage/api-source.candidate-483360250627e4fc99a9cd519582e3b7b948fae9/src/
scp .\api\src\auth\cognito.ts ubuntu@<SERVER>:/home/ubuntu/shattab-pg18-stage/api-source.candidate-483360250627e4fc99a9cd519582e3b7b948fae9/src/auth/
```

قارن كل بصمات `Get-FileHash` المحلية ببصمات الملفات على السيرفر. لازم كل ملف يطابق؛ أي اختلاف أو ملف ناقص يوقف النقل:

```bash
sudo sha256sum /home/ubuntu/shattab-pg18-stage/api-source.candidate-483360250627e4fc99a9cd519582e3b7b948fae9/Dockerfile /home/ubuntu/shattab-pg18-stage/api-source.candidate-483360250627e4fc99a9cd519582e3b7b948fae9/package.json /home/ubuntu/shattab-pg18-stage/api-source.candidate-483360250627e4fc99a9cd519582e3b7b948fae9/package-lock.json /home/ubuntu/shattab-pg18-stage/api-source.candidate-483360250627e4fc99a9cd519582e3b7b948fae9/tsconfig.json /home/ubuntu/shattab-pg18-stage/api-source.candidate-483360250627e4fc99a9cd519582e3b7b948fae9/.dockerignore /home/ubuntu/shattab-pg18-stage/api-source.candidate-483360250627e4fc99a9cd519582e3b7b948fae9/src/app.ts /home/ubuntu/shattab-pg18-stage/api-source.candidate-483360250627e4fc99a9cd519582e3b7b948fae9/src/config.ts /home/ubuntu/shattab-pg18-stage/api-source.candidate-483360250627e4fc99a9cd519582e3b7b948fae9/src/database.ts /home/ubuntu/shattab-pg18-stage/api-source.candidate-483360250627e4fc99a9cd519582e3b7b948fae9/src/server.ts /home/ubuntu/shattab-pg18-stage/api-source.candidate-483360250627e4fc99a9cd519582e3b7b948fae9/src/auth/cognito.ts
```

بعد التطابق فقط، احفظ المصدر القديم باسم نسخة احتياطية جديدة من غير استبدال، ثم انقل المرشح إلى `api-source` الذي يستخدمه Compose. لو اسم النسخة الاحتياطية موجود أو أي مجلد غير متوقع، توقّف ولا تنفذ النقل. لو نقل المرشح فشل بعد حفظ المصدر القديم، لا تحذف أي مجلد؛ بعد فحص أن `api-source` غير موجود وأن backup هو المصدر القديم فقط، أعده بأمر `sudo test ! -e /home/ubuntu/shattab-pg18-stage/api-source && sudo mv -T /home/ubuntu/shattab-pg18-stage/api-source.previous-483360250627e4fc99a9cd519582e3b7b948fae9 /home/ubuntu/shattab-pg18-stage/api-source`:

```bash
sudo test -d /home/ubuntu/shattab-pg18-stage/api-source && sudo test ! -L /home/ubuntu/shattab-pg18-stage/api-source && sudo test ! -e /home/ubuntu/shattab-pg18-stage/api-source.previous-483360250627e4fc99a9cd519582e3b7b948fae9 && sudo test ! -L /home/ubuntu/shattab-pg18-stage/api-source.previous-483360250627e4fc99a9cd519582e3b7b948fae9 && sudo mv -T /home/ubuntu/shattab-pg18-stage/api-source /home/ubuntu/shattab-pg18-stage/api-source.previous-483360250627e4fc99a9cd519582e3b7b948fae9 && sudo mv -T /home/ubuntu/shattab-pg18-stage/api-source.candidate-483360250627e4fc99a9cd519582e3b7b948fae9 /home/ubuntu/shattab-pg18-stage/api-source
```

احتفظ بالنسخة القديمة ولا تمسحها. ملفات Compose والأدوات تفضل في مجلدها المحمي؛ لا ترفع ملف Compose أو تستبدل snapshot ضمن هذه الخطوة.

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

أولًا افحص UID/GID من صورة Node الأساسية المثبتة بنفس `digest` (بصمة محتوى ثابتة) الموجودة في Dockerfile. الأمر ده قد ينزّل الصورة لو مش موجودة محليًا، لكنه ما يشغّليش خدمة دائمة ولا يفتح منفذ:

```bash
sudo docker run --rm --entrypoint id node:24.22.1-bookworm-slim@sha256:55fb5f5a527ea2c5c4a95f963e48ef90aa38c7b346054fdc8ee9957a2b55d205 node
```

اقرأ رقم `uid` ورقم `gid` في النتيجة، ولا تفترض إنهم `1000:1000`. سجّل الرقمين للمقارنة فقط؛ ما تغيّرش كلمة المرور أو تنشئ ملف السر لسه.

خطوات الـbootstrap في القسم 2 تنشئ مجلد الأسرار لو مش موجود وتتحقق إن وضعه `0700` وملكيته `root`. لا تصلّح المسارات يدويًا باستخدام `chown` أو `chmod`؛ عند أي اختلاف، وقف للمراجعة. `Docker daemon` (خدمة Docker اللي بتشغّل الحاويات بصلاحية النظام) يقرأ الملف عند تشغيل Compose بـ`sudo`.

افحص إعداد Compose بصمت قبل البناء. لازم نجاحه من غير output؛ أي خطأ يوقف الخطوات:

```bash
cd /home/ubuntu/shattab-pg18-stage && sudo docker compose --env-file /dev/null --project-directory /home/ubuntu/shattab-pg18-stage -f /root/shattab-pg18-stage-tools/compose.3216004984ca41882f0cc59b6e625e4f88da2f08575e484d7167a5b0c783d008.yaml -p shattab-pg18-stage config --quiet
```

ابنِ صورة API على السيرفر باستخدام Dockerfile متعدد المراحل (يبني التطبيق ثم ينسخ ملفات التشغيل اللازمة فقط للصورة النهائية):

```bash
sudo docker compose --env-file /dev/null --project-directory /home/ubuntu/shattab-pg18-stage -f /root/shattab-pg18-stage-tools/compose.3216004984ca41882f0cc59b6e625e4f88da2f08575e484d7167a5b0c783d008.yaml -p shattab-pg18-stage build api
```

البناء يحتاج اتصالًا لتنزيل صور Node/حزم npm وقد يستهلك مساحة وبيانات نقل. لا يفتح منفذًا ولا ينشئ جداول. بعد البناء، افحص UID/GID للمستخدم داخل صورة API النهائية:

```bash
sudo docker run --rm --entrypoint id shattab-api:stage node
```

لازم UID/GID يطابقوا الرقمين اللي سجّلتهم من صورة Node الأساسية، والـUID يفضل غير صفر. لو اختلفوا أو مش واضحين، ما تغيّرش كلمة المرور وما تنشئش السر وما تشغّلش الخدمة؛ راجع مصدر الاختلاف الأول. حضّر متغيرات shell من الصورة النهائية الآن، قبل أي تغيير لكلمة المرور:

```bash
NODE_UID=$(sudo docker run --rm --entrypoint id shattab-api:stage -u node) && NODE_GID=$(sudo docker run --rm --entrypoint id shattab-api:stage -g node) && test -n "$NODE_UID" && test -n "$NODE_GID" && test "$NODE_UID" -gt 0 && printf 'verified node uid=%s gid=%s\n' "$NODE_UID" "$NODE_GID"
```

خلي جلسة SSH نفسها مفتوحة عشان قيم `NODE_UID` و`NODE_GID` تفضل متاحة للمساعد بعد تغيير كلمة المرور. لو خرجت من الجلسة، أعد فحوص هوية الصورة وحضّر المتغيرات من جديد قبل أي كتابة.

قبل أي تغيير للسر أو إنشاء ملفه، تأكد إن قاعدة المرحلة `db` بالحالة `healthy` باستخدام ملف Compose المحمي:

```bash
sudo docker compose --env-file /dev/null --project-directory /home/ubuntu/shattab-pg18-stage -f /root/shattab-pg18-stage-tools/compose.3216004984ca41882f0cc59b6e625e4f88da2f08575e484d7167a5b0c783d008.yaml -p shattab-pg18-stage ps db
```

لازم الحالة الظاهرة تكون `healthy`. لو الحالة مختلفة أو الأمر فشل، وقف من غير تغيير السر. أعد الفحص قبل تشغيل API كمان.

**بعد نجاح كل فحوص المصدر والبناء والهوية وCompose وصحة قاعدة البيانات فقط، وقبل تشغيل API مباشرةً، غيّر كلمة المرور وأنشئ ملفها.** افحص تاني إن الملف مش موجود ولا symlink وإن مجلد الأسرار يطابق `root:root` و`0700` حسب القسم 6.4. لو ظهرت حالة مختلفة، توقف.

قبل كتابة كلمة المرور مباشرةً، خُد inventory snapshot جديدًا من `postgres` وقارنه باللقطة السابقة. بعد نجاح المقارنة، أعد تشغيل `validate_database_inventory` و`run_catalog_guard_for_snapshot` على كل قاعدة `datallowconn=true`؛ ده يعيد فحص ACLs والمالك والصلاحيات الفعالة و`pg_default_acl` وحالة الدور، فيكشف تغيير ACL أو role حتى لو أسماء القواعد وحالة الاتصال ما اتغيرتش. بعد الفحص الكامل، خُد snapshot أخيرًا وقارنه باللقطة الجديدة؛ يفتح الأمر التفاعلي التالي فقط لو كل الفحوص نجحت. بعد فتح `psql` اكتب `\password shattab_api`. لو الجلسة اتقفلت أو المتغيرات مش موجودة، أعد الحلقة الأولى كاملة في جلسة جديدة ولا تنفذ الأمر:

```bash
DB_SNAPSHOT_BEFORE_PASSWORD=$("${COMPOSE[@]}" exec -T db psql -X -A -t -v ON_ERROR_STOP=1 -U shattab_stage_admin -d postgres -c "$DB_INVENTORY_SQL") && test -n "$DB_SNAPSHOT_BEFORE_PASSWORD" && test "$DB_SNAPSHOT_BEFORE_PASSWORD" = "$DB_SNAPSHOT_INITIAL" || { printf 'FAIL: PostgreSQL database inventory changed before password write; restart the full guard.\n' >&2; exit 1; }
validate_database_inventory "$DB_SNAPSHOT_BEFORE_PASSWORD" || { printf 'FAIL: invalid PostgreSQL database inventory before password write; stop.\n' >&2; exit 1; }
run_catalog_guard_for_snapshot "$DB_SNAPSHOT_BEFORE_PASSWORD" || { printf 'FAIL: a pre-password database catalog guard failed; stop.\n' >&2; exit 1; }
DB_SNAPSHOT_AFTER_PASSWORD_GUARD=$("${COMPOSE[@]}" exec -T db psql -X -A -t -v ON_ERROR_STOP=1 -U shattab_stage_admin -d postgres -c "$DB_INVENTORY_SQL")
test "$DB_SNAPSHOT_AFTER_PASSWORD_GUARD" = "$DB_SNAPSHOT_BEFORE_PASSWORD" || { printf 'FAIL: PostgreSQL database inventory changed during the pre-password guard; restart the full guard.\n' >&2; exit 1; }
```

افتح جلسة تفاعلية على قاعدة المرحلة:

```bash
sudo docker compose --env-file /dev/null --project-directory /home/ubuntu/shattab-pg18-stage -f /root/shattab-pg18-stage-tools/compose.3216004984ca41882f0cc59b6e625e4f88da2f08575e484d7167a5b0c783d008.yaml -p shattab-pg18-stage exec -it db psql -X -U shattab_stage_admin -d shattab_stage
```

داخل `psql` نفّذ الأمر التالي، واكتب السر العشوائي الجاهز مرتين في المطالبتين المخفيتين:

```text
\password shattab_api
```

`\password` يغيّر كلمة مرور الدور عبر prompt مخفي، من غير إدخالها في `argv` (وسائط سطر الأوامر) أو `env` (متغيرات البيئة) أو SQL ظاهر أو سجل shell. هو لا ينشئ الدور ولا يغيّر grants أو role attributes. بعد نجاحه، اخرج من `psql` ولا تنشئ ملف السر يدويًا.

المساعد المثبّت في `/root/shattab-pg18-stage-tools/create_api_secret.py` يثبت مجلد المرحلة ومجلد الأسرار بأوصاف ملفات مفتوحة ويفحصهما عبر `fstat`. قبل طلب السر، يفحص غياب الملف باستخدام `dir_fd` (مرجع لمجلد مفتوح)؛ أي ملف أو رابط موجود يوقف العملية من غير `overwrite` (كتابة فوق الموجود). `getpass` (إدخال تفاعلي ما بيعرضش الأحرف) يطلب السر مرتين للمطابقة، والمساعد يرفض الطرفية غير التفاعلية أو طول/ترميز/محارف غير مسموحة، يكتب ملفًا مؤقتًا بصلاحية خاصة، ثم ينشره نسبةً لوصف المجلد المثبّت ومن غير استبدال ملف موجود. لو فشل حذف الملف المؤقت، هيرجع خطأ واضح إن السر قد يكون نُشر وإن ملفًا مؤقتًا ممكن يفضل؛ افحص الحالة يدويًا قبل أي إعادة محاولة. الأخطاء لا تطبع قيمة السر.

استخدم متغيرات `NODE_UID` و`NODE_GID` اللي حضرتها من الصورة النهائية قبل تغيير كلمة المرور؛ مفيش قيم افتراضية أو `1000:1000`. نفّذ المساعد من نفس جلسة SSH:

```bash
sudo python3 /root/shattab-pg18-stage-tools/create_api_secret.py --node-uid "$NODE_UID" --node-gid "$NODE_GID"
```

لو المتغيرين مش موجودين أو فحص الهوية فشل، ما تنفذش الأمر بقيم ثابتة؛ ارجع لفحوص الصورة قبل أي كتابة أخرى. المساعد المثبت في `/root/shattab-pg18-stage-tools/create_api_secret.py` ينشئ الملف بجانبه في `/root/shattab-pg18-stage-tools/secrets/api_password` بمالك `root` ومجموعة GID الخاصة بـ`node`، يعني `root:<process-gid>`، ووضع `0440` (قراءة للمالك والمجموعة فقط). لا يغير ملفات الأسرار الموجودة. المساعد يراجع metadata (بيانات النوع والملكية والصلاحيات) من غير قراءة محتوى السر أو عرضه. المتوقع `700` للمجلد و`440 0:<GID>` لملف السر. لو فشل المساعد أو ظهر ملف جزئي/موجود، سيب الحالة زي ما هي ووقف للمراجعة؛ ما تمسحش الملف وما تعيدش إنشاءه تلقائيًا. الملف مش مشفر على قرص السيرفر؛ مدير السيرفر وDocker يقدروا يقرؤوه.

بعد إنشاء الملف، أعد `config --quiet` بصمت قبل التشغيل؛ لازم ينجح من غير output. لو فشل، ما تشغّلش API؛ ما تحذفش السر أو تغيّر كلمة المرور تلقائيًا، وافحص السبب وخطة الاستعادة.

قبل التشغيل، تأكد إن خدمة `db` ظاهرة `healthy` في `docker compose ps db`؛ لو مش سليمة توقّف. بعد تطابق الهوية ونجاح فحص السر، شغّل API وحدها من غير إعادة تشغيل قاعدة البيانات:

```bash
sudo docker compose --env-file /dev/null --project-directory /home/ubuntu/shattab-pg18-stage -f /root/shattab-pg18-stage-tools/compose.3216004984ca41882f0cc59b6e625e4f88da2f08575e484d7167a5b0c783d008.yaml -p shattab-pg18-stage up -d --no-deps --no-build api
```

`--no-deps` يمنع Compose من لمس خدمة قاعدة البيانات؛ لذلك لازم تتأكد من `healthy` قبل الأمر. API تتصل بقاعدة المرحلة عبر الشبكة الداخلية فقط، ومفيش `ports` منشورة. لو فشل التشغيل، استخدم `stop api` في القسم 6.6؛ ما توقفش قاعدة البيانات وما تحذفش الـvolume أو السر.

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

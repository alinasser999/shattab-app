# PostgreSQL 18 staging على Oracle

دي قاعدة PostgreSQL (قاعدة بيانات علائقية) فاضية للتجارب المرحلية على سيرفر Oracle. مش قاعدة إنتاج، ومفيش بيانات أو migrations (ملفات تغييرات مخطط قاعدة البيانات) أو مستخدمين من Supabase اتنقلوا لها. تشغيلها ما معناهش إن تطبيق شطب اتنشر.

## 1. مكونات الحزمة

`Docker Compose` (أداة بتعرّف خدمة قاعدة البيانات وشبكتها وتخزينها من ملف إعداد واحد) بيشغّل خدمة واحدة اسمها `db` ضمن المشروع `shattab-pg18-stage`.

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

أنشئ المجلدات كمستخدم `ubuntu`. استخدام `mkdir` العادي يخلي الأمر يفشل لو الاسم موجود بدل تعديل محتواه:

```bash
sudo -u ubuntu mkdir -m 700 /home/ubuntu/shattab-pg18-stage && sudo -u ubuntu mkdir -m 700 /home/ubuntu/shattab-pg18-stage/secrets
```

انقل الملفات غير السرية فقط من `Windows PowerShell` بعد إنشاء المسار. استبدل `<SERVER>` بعنوان السيرفر الموثق عندك؛ ما تحطش كلمة السر في أمر `scp`:

```powershell
scp .\infra\postgres18-stage\compose.yaml ubuntu@<SERVER>:/home/ubuntu/shattab-pg18-stage/
```

```powershell
scp .\infra\postgres18-stage\verify.py ubuntu@<SERVER>:/home/ubuntu/shattab-pg18-stage/
```

```powershell
scp .\infra\postgres18-stage\README.md ubuntu@<SERVER>:/home/ubuntu/shattab-pg18-stage/
```

ولّد كلمة سر عشوائية على السيرفر. الأمر بيتأكد إن ملف السر مش موجود، ويستخدم مولد `openssl` العشوائي، وما بيعرضش القيمة على الشاشة:

```bash
sudo -u ubuntu sh -c 'set -eu; set -C; cd /home/ubuntu/shattab-pg18-stage; umask 077; test ! -e secrets/postgres_password; test ! -L secrets/postgres_password; openssl rand -hex 32 > secrets/postgres_password; chmod 600 secrets/postgres_password'
```

`umask 077` (إعداد يمنع منح صلاحيات للآخرين عند إنشاء الملف) مع `chmod 600` يخلي قراءة الملف وكتابته للمالك فقط. `set -C` بيفعّل منع الكتابة فوق ملف موجود، عشان توليد السر يبقى حصري وما يستبدلش سرًا سابقًا. شغّله مرة واحدة بعد الفحص. لو فشل بعد إنشاء ملف جزئي، ما تحذفوش أو تعيد المحاولة تلقائيًا؛ وقف وراجع الحالة.

راجع الصلاحيات والمالك من غير عرض المحتوى:

```bash
sudo stat -c '%a %U:%G %n' /home/ubuntu/shattab-pg18-stage /home/ubuntu/shattab-pg18-stage/secrets /home/ubuntu/shattab-pg18-stage/secrets/postgres_password
```

المتوقع `700` للمجلدين و`600` للملف، والمالك `ubuntu`. ما تستخدمش `cat` أو `echo` لملف السر، وما تضيفوش لأي نسخة احتياطية أو repository (مستودع ملفات المشروع) من غير قرار منفصل.

## 3. فحص الإعداد وتشغيل القاعدة

كل الأوامر الجاية على السيرفر ومن داخل `/home/ubuntu/shattab-pg18-stage`. `sudo` يشغل Docker بصلاحيات مدير النظام؛ الوصول لـ Docker daemon (خدمة إدارة الحاويات) يعادل صلاحيات واسعة على السيرفر.

```bash
cd /home/ubuntu/shattab-pg18-stage
```

تحقق من الملف من غير طباعة الإعدادات:

```bash
sudo docker compose --env-file /dev/null -f compose.yaml -p shattab-pg18-stage config --quiet
```

`--env-file /dev/null` يمنع Compose من تحميل ملف `.env` تلقائي، و`-f` يحدد ملف الإعداد، و`-p` يثبت اسم المشروع، و`--quiet` يطلب التحقق من غير عرض القيم. النجاح عادةً بيرجع من غير output؛ أي خطأ يوقف التشغيل للمراجعة.

نزّل الصورة المثبتة، وبعدها شغّل الخدمة في الخلفية:

```bash
sudo docker compose --env-file /dev/null -f compose.yaml -p shattab-pg18-stage pull db
```

```bash
sudo docker compose --env-file /dev/null -f compose.yaml -p shattab-pg18-stage up -d db
```

`pull` (تنزيل الصورة) يستهلك مساحة وبيانات اتصال. `up -d` ينشئ الشبكة الداخلية والـ volume والحاوية ويشغّل قاعدة البيانات. أول تشغيل فقط يهيّئ قاعدة فارغة؛ ما بيشغّلش migrations لشطب.

راجع الحالة:

```bash
sudo docker compose --env-file /dev/null -f compose.yaml -p shattab-pg18-stage ps db
```

استنى لحد ما الحالة تبقى `healthy`، وبعدين شغّل أداة التحقق:

```bash
sudo python3 verify.py
```

الأداة بتتحقق من اسم المشروع والحاوية، إصدار الصورة ومعمارية `ARM64`، الحالة الصحية، حدود الموارد، سياسة عدم إعادة التشغيل، تدوير السجلات، الـ volume ومسار PG18، الشبكة الداخلية وغياب نشر المنافذ. بعدها بتستخدم عميل PostgreSQL مؤقتًا داخل نفس الشبكة لتثبت دخول TCP بكلمة السر، ونسخة `18.6` ورقم `180006`، ووجود إعداد `SCRAM`، وعدم وجود جداول أو علاقات تطبيقية. المتوقع `PASS` من غير أي كلمة سر.

ملف `pgpass` (ملف مؤقت يمرر بيانات الدخول لعميل PostgreSQL) بيتكتب في `/tmp` خارج المشروع بصلاحية `600`. الأداة ما بتحطش كلمة السر في وسيطات الأوامر أو السجلات، وما بتحذف الملف إلا بعد ما تأكد إزالة حاوية العميل. لو تعذر تأكيد التنظيف، الأداة تفشل وتسيب الملف بصلاحية محمية وتطبع مساره فقط للمراجعة؛ ما تحذفهش قبل التأكد من عدم وجود حاوية بتستخدمه.

## 4. الإيقاف والاستئناف الآمن

بعد نجاح التحقق، أوقف الخدمة مع الاحتفاظ بالحاوية والبيانات والسر:

```bash
sudo docker compose --env-file /dev/null -f compose.yaml -p shattab-pg18-stage stop db
```

`stop` يوقف قاعدة البيانات ويحرر CPU وRAM، لكنه لا يحذف الـ volume. ما تستخدمش `down -v` أو `docker volume rm` أو أوامر تنظيف في هذه المرحلة.

للاستئناف لاحقًا بعد التأكد من الحالة والاحتياج، شغّلها صراحةً:

```bash
sudo docker compose --env-file /dev/null -f compose.yaml -p shattab-pg18-stage start db
```

بعد `start` راجع `ps db` لحد `healthy`، ثم أعد `sudo python3 verify.py`. ثبات اسم المشروع والـ volume مهم؛ تغيير الاسم ممكن ينشئ volume جديدًا فاضيًا.

لو أي فحص فشل بعد الإنشاء، أوقف خدمة `shattab-pg18-stage` وحدها واترك الـ volume والسر للتحقيق. ما توقفش أو تعدّل `shattab-lab`، وما تحذفش بيانات لأي سبب كجزء من الرجوع. إيقاف هذه القاعدة لا يغيّر قواعد firewall أو قواعد OCI ولا يفتح المنفذ 5432.

## 5. حدود الدليل

نجاح فحص الإعداد محليًا ما يثبتش إن الملفات اترفعت أو إن قاعدة البيانات اشتغلت على Oracle. التشغيل الفعلي لازم يتوثق من مخرجات السيرفر ومقارنة حالة `shattab-lab` قبل وبعد. قاعدة staging دي فاضية ومؤقتة؛ مش نسخة احتياطية، ومش قاعدة تطبيق، ومش دليل نشر أو جاهزية إنتاج.

## 6. تكامل API تجريبي — مخطط فقط، غير منفذ

القسم ده يشرح تجهيز اتصال داخلي لخدمة API (واجهة خدمات بتستقبل طلبات التطبيقات) الموجودة في `api/` مع قاعدة PostgreSQL 18 التجريبية. الـ API لسه health-only (وظيفته الحالية فحص إن العملية وقاعدة البيانات شغالين) وبيشغّل استعلام ثابت `SELECT 1`. مفيش جداول شطب أو بيانات مستخدمين أو ميزات تطبيقية في النطاق ده، ومش بديل لـ Supabase.

**مفيش خطوة في القسم ده اتنفذت على Oracle.** رفع الملفات أو تشغيل الخدمة أو إنشاء دور/سر على السيرفر يحتاج موافقة صريحة منفصلة بعد مراجعة التغيير المحلي ده. ما تنفذش الخطوات دي أثناء مراجعة الكود.

### 6.1 شكل الاتصال وحدوده

| الإعداد | القيمة والخبرة المطلوبة |
| --- | --- |
| مصدر البناء | ملفات API غير السرية فقط في `/home/ubuntu/shattab-pg18-stage/api-source/`، بجانب `compose.yaml` وليس داخل مجلد المشروع المحلي على السيرفر. |
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
cd /home/ubuntu/shattab-pg18-stage && sudo docker compose --env-file /dev/null -f compose.yaml -p shattab-pg18-stage config --quiet
```

`--quiet` يطلب التحقق من الملف من غير عرضه. لو رجع خطأ، وقف. بعد الفحص، تحقق إن ملف السر الجديد مش موجود، وإن مجلد الأسرار لسه `0700`:

```bash
sudo stat -c '%a %U:%G %n' /home/ubuntu/shattab-pg18-stage /home/ubuntu/shattab-pg18-stage/secrets && sudo test ! -e /home/ubuntu/shattab-pg18-stage/secrets/api_password && sudo test ! -L /home/ubuntu/shattab-pg18-stage/secrets/api_password
```

لازم مساري المجلد يظهروا `700`، واختبارا `test` يكمّلوا من غير رسالة. لو السر موجود أو الحالة مبهمة، ما تستبدلوش.

### 6.3 نقل ملفات التشغيل بعد الموافقة

مجلد النشر على السيرفر منفصل عن المستودع المحلي. احتفظ بنسخة رجوع من ملف Compose القديم على السيرفر قبل استبداله:

```bash
sudo cp -a --no-clobber /home/ubuntu/shattab-pg18-stage/compose.yaml /home/ubuntu/shattab-pg18-stage/compose.yaml.pre-api
```

`--no-clobber` يمنع الكتابة فوق نسخة رجوع موجودة. لو النسخة موجودة بالفعل، افحصها ولا تغيرها. من `Windows PowerShell` (طرفية ويندوز)، ارفع ملفات الفحص غير السرية فقط إلى مجلد المرحلة:

```powershell
scp .\infra\postgres18-stage\README.md .\infra\postgres18-stage\verify.py .\infra\postgres18-stage\preflight_api_role.sql .\infra\postgres18-stage\create_api_role.sql ubuntu@<SERVER>:/home/ubuntu/shattab-pg18-stage/
```

ابدأ قاعدة PG18 حسب الأقسام 3 و4 من هذا الدليل، ثم شغّل `sudo python3 verify.py`. لازم تنجح أداة التحقق قبل أي إنشاء دور/سر؛ هي بتراجع هوية الحاوية وصورة PostgreSQL والشبكة والـ volume، وبتتحقق من `PGDATA` الفعلي بإعداد `current_setting('data_directory')` أثناء اتصالها بدور `shattab_stage_admin`. في إعداد Compose الحالي، `POSTGRES_USER` بيعمل الدور ده كـ `superuser` (حساب PostgreSQL بصلاحيات كاملة) عند تهيئة قاعدة المرحلة. لا تشغل `infra/postgres-lab` أو أي أداة تخصه.

في اختبار CI، دور `shattab_stage_admin` بيتعمل عمدًا بصلاحية أقل (`LOGIN CREATEROLE`) عشان نختبر فحوص SQL بأقل صلاحيات لازمة. لذلك harness الاختبار (برنامج الاختبار المعزول) بيفحص المسار الفعلي باستعلام قراءة فقط كـ `postgres` superuser داخل الحاوية المقفولة، وبعد تأكيد صحتها وقبل إنشاء أي fixture. ملفات SQL نفسها تراجع هوية قاعدة البيانات والدور والإصدار ومخطط قاعدة البيانات وصلاحيات `PUBLIC`؛ ما بتقرأش `data_directory` أو بتحتاج `pg_read_all_settings`.

بعد نجاح التحقق، شغّل الفحص الإضافي للـ catalog (كتالوج قاعدة البيانات الذي يسجل المخططات والأدوار والصلاحيات). ده فحص قراءة فقط:

```bash
sudo docker compose --env-file /dev/null -f compose.yaml -p shattab-pg18-stage exec -T db psql -X -v ON_ERROR_STOP=1 -U shattab_stage_admin -d shattab_stage -f - < preflight_api_role.sql
```

النتيجة تعرض أعداد المخططات والعلاقات والدوال والأنواع والامتدادات والكائنات الكبيرة، وحالة الدور، وصلاحيات `PUBLIC` (الصلاحيات العامة لكل أدوار PostgreSQL)، وأي `default ACL` (صلاحيات افتراضية تُمنح تلقائيًا للكائنات الجديدة). الفحص يسمح فقط بالافتراضيات القياسية في قاعدة PostgreSQL 18 جديدة: `USAGE` على مخطط `public`، و`CONNECT` و`TEMPORARY` على قاعدة البيانات. لازم كل واحدة تظهر مرة واحدة ومن غير `WITH GRANT OPTION`. أي صلاحية إضافية على المخططات أو كائنات التطبيق أو قاعدة البيانات توقف الإجراء. لازم كمان ما يكونش فيه أي جدول أو دالة أو نوع أو امتداد أو كائن كبير خاص بالتطبيق، ولا أي `default ACL` صريح. في حالة الكائنات الكبيرة، الفحص يقرأ `pg_largeobject_metadata` (كتالوج فيه مالك الكائن وصلاحياته) ويفحص `lomacl` أو الافتراضي من `acldefault('L', lomowner)` عبر `aclexplode`؛ ما بيقرأش بيانات الكائن نفسها. وجود أي كائن كبير أو صلاحية `PUBLIC` عليه يوقف الإجراء. تفاصيل الحقول في [كتالوج PostgreSQL 18 للكائنات الكبيرة](https://www.postgresql.org/docs/18/catalog-pg-largeobject-metadata.html) و[دالة `acldefault` و`aclexplode`](https://www.postgresql.org/docs/18/functions-info.html). ما بتظهرش كلمة سر أو بيانات مستخدمين.

فحص SQL ده بيتأكد من عقد صلاحيات قاعدة البيانات فقط، ومش مسؤول عن `PGDATA` أو مسار الملفات؛ `verify.py` راجعهم بالفعل قبل تشغيله. في CI الاختبار السلوكي بيعيد فحص المسار الفعلي كـ `postgres` superuser في الحاوية المؤقتة قبل أي SQL تعديلي.

الفحص كمان بيعرض إن PostgreSQL القياسي بيدي `EXECUTE` لـ`PUBLIC` على أي دالة جديدة افتراضيًا. ده مش كائن موجود دلوقتي، لكن معناه إن إضافة دوال مستقبلًا ممكن تدي كل الأدوار صلاحية تنفيذها. لذلك أي migration أو إضافة دالة/كائن للتطبيق محتاجة مراجعة منفصلة وإعادة فحص الصلاحيات قبل تشغيل API؛ ما تغيّرش الافتراضيات القياسية تلقائيًا أثناء تجهيز الدور.

### 6.4 إنشاء دور قاعدة البيانات

بعد `PASS` فقط، شغّل ملف إنشاء الدور المحمي بفحوص هوية قاعدة البيانات والإصدار، وغياب الدور وكائنات التطبيق، ومطابقة صلاحيات `PUBLIC` الافتراضية. مسار البيانات اتراجع منفصلًا بواسطة `verify.py` قبل الفحص ده. الملف يفتح معاملة واحدة؛ لو الشروط مش مطابقة، ما يعملش إنشاء. لازم تكون مخرجات الفحص السابق ما زالت حديثة وما حصلش أي تغيير إداري بينها وبين الأمر ده:

```bash
sudo docker compose --env-file /dev/null -f compose.yaml -p shattab-pg18-stage exec -T db psql -X -v ON_ERROR_STOP=1 -U shattab_stage_admin -d shattab_stage -f - < create_api_role.sql
```

الدور `shattab_api` يقدر يسجل دخول، لكنه مش مالك قاعدة أو مخطط أو جدول، ومش `superuser`، وما يقدرش ينشئ قواعد أو أدوار أو يتجاوز `RLS`، وما عندوش عضوية في أدوار تانية. له حد 3 اتصالات، و`search_path=pg_catalog` (ترتيب المخططات اللي PostgreSQL بيدور فيها على الأسماء؛ هنا بيخلي البحث غير المؤهل داخل كتالوج النظام فقط). الدور بياخد افتراضيات `PUBLIC` القياسية اللي كل دور بيستفيد منها تلقائيًا حتى مع `NOINHERIT`: `USAGE` على `public` و`CONNECT` و`TEMPORARY` على قاعدة المرحلة. `TEMPORARY` بيسمح بإنشاء جداول مؤقتة داخل الجلسة؛ الـAPI الحالي ما بيعملش ده، واختيار تعطيله محتاج تغيير سياسة منفصل ومراجَع. دي صلاحيات baseline (الحد الافتراضي المشترك)، مش منحًا إضافيًا من ملف إنشاء الدور. مفيش جدول أو دالة تطبيقية موجودة أو صلاحيات عليها، والـAPI حاليًا بيعمل `SELECT 1` بس. الملف ما يحتويش كلمة سر. بعد نجاح الإنشاء، افتح جلسة `psql` تفاعلية:

```bash
sudo docker compose --env-file /dev/null -f compose.yaml -p shattab-pg18-stage exec -it db psql -X -U shattab_stage_admin -d shattab_stage
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

بعد نجاح الرفع، ارفع ملف Compose المحدّث ومساعد إنشاء السر إلى جذر مجلد المرحلة. تأكد إن نسخة `compose.yaml.pre-api` محفوظة، وما تنقلش أي `.env` أو secret:

```powershell
scp .\infra\postgres18-stage\compose.yaml ubuntu@<SERVER>:/home/ubuntu/shattab-pg18-stage/
```

```powershell
scp .\infra\postgres18-stage\create_api_secret.py ubuntu@<SERVER>:/home/ubuntu/shattab-pg18-stage/
```

أولًا افحص UID/GID من صورة Node الأساسية المثبتة بنفس `digest` (بصمة محتوى ثابتة) الموجودة في Dockerfile. الأمر ده قد ينزّل الصورة لو مش موجودة محليًا، لكنه ما يشغّلش خدمة دائمة ولا يفتح منفذ:

```bash
sudo docker run --rm --entrypoint id node:24.22.1-bookworm-slim@sha256:55fb5f5a527ea2c5c4a95f963e48ef90aa38c7b346054fdc8ee9957a2b55d205 node
```

اقرأ من النتيجة رقم `uid` ورقم `gid` للمستخدم `node`. لازم `uid` يكون غير صفر. ما تفترضش إن الأرقام `1000:1000`؛ استخدم القيم اللي ظهرت فعلًا.

قبل تشغيل المساعد، افحص مجلد الأسرار نفسه من غير قراءة أي ملف داخله:

```bash
sudo test -d /home/ubuntu/shattab-pg18-stage/secrets && sudo test ! -L /home/ubuntu/shattab-pg18-stage/secrets && sudo stat -c '%F %a %u:%g %n' /home/ubuntu/shattab-pg18-stage/secrets
```

لو المجلد حقيقي، ثبّت ملكيته وصلاحيته ثم تحقق من النتيجة:

```bash
sudo chown root:root /home/ubuntu/shattab-pg18-stage/secrets && sudo chmod 700 /home/ubuntu/shattab-pg18-stage/secrets && sudo stat -c '%a %u:%g %n' /home/ubuntu/shattab-pg18-stage/secrets
```

المتوقع بالضبط `700 0:0`. لو الأمر رجّع غير كده، وقف وما تشغّلش المساعد. التغيير ده يضبط مجلد الأسرار فقط ولا يبدّل محتوى ملف `postgres_password`؛ Docker daemon (خدمة Docker اللي بتشغّل الحاويات بصلاحية النظام) يقرأ الملف عند تشغيل Compose بـ`sudo`.

قبل المساعد، اتأكد إن ملف السر الجديد غير موجود، سواء كان ملف عادي أو رابطًا رمزيًا:

```bash
sudo test ! -e /home/ubuntu/shattab-pg18-stage/secrets/api_password && sudo test ! -L /home/ubuntu/shattab-pg18-stage/secrets/api_password
```

لو الملف موجود، المساعد هيرفضه قبل المطالبات ومش هيعمل overwrite (كتابة فوق الموجود). افحص الحالة يدويًا من غير عرض المحتوى، وما تمسحوش أو تستبدلوش تلقائيًا. لو الملف غائب، شغّل المساعد. `getpass` (إدخال تفاعلي ما بيعرضش الأحرف) يطلب السر مرتين للمطابقة، والمساعد يرفض الطرفية غير التفاعلية أو طول/ترميز/محارف غير مسموحة، يكتب ملفًا مؤقتًا بصلاحية خاصة، ثم ينشره من غير استبدال ملف موجود. لو فشل حذف الملف المؤقت، هيرجع خطأ واضح إن السر قد يكون نُشر وإن ملفًا مؤقتًا ممكن يفضل؛ افحص المسارين يدويًا قبل أي إعادة محاولة. الأخطاء لا تطبع قيمة السر:

```bash
sudo python3 create_api_secret.py --node-uid 1000 --node-gid 1000
```

الأرقام في مثال المساعد مجرد مثال؛ استبدلها بالـ UID/GID اللذين أظهرهما أمر `id` قبل التنفيذ. المساعد ينشئ `/home/ubuntu/shattab-pg18-stage/secrets/api_password` بمالك `root` ومجموعة GID الخاصة بـ`node`، يعني `root:<process-gid>`، ووضع `0440` (قراءة للمالك والمجموعة فقط). لا يغير ملفات الأسرار الموجودة. بعد النجاح، اعرض بيانات الملف فقط:

```bash
sudo stat -c '%a %u:%g %n' /home/ubuntu/shattab-pg18-stage /home/ubuntu/shattab-pg18-stage/secrets /home/ubuntu/shattab-pg18-stage/secrets/api_password
```

المتوقع `700` للمجلدين و`440 0:<GID>` لملف السر، حيث `<GID>` هو نفس الرقم المتحقق منه. لو فشل المساعد أو ظهر ملف جزئي/موجود، سيب الحالة زي ما هي ووقف للمراجعة؛ ما تمسحش الملف وما تعيدش إنشاءه تلقائيًا. الملف مش مشفر على قرص السيرفر؛ مدير السيرفر وDocker يقدروا يقرؤوه.

بعد وجود السر، افحص إعداد Compose بصمت. لازم نجاحه من غير output؛ أي خطأ يوقف البناء:

```bash
cd /home/ubuntu/shattab-pg18-stage && sudo docker compose --env-file /dev/null -f compose.yaml -p shattab-pg18-stage config --quiet
```

ابنِ صورة API على السيرفر باستخدام Dockerfile متعدد المراحل (يبني التطبيق ثم ينسخ ملفات التشغيل اللازمة فقط للصورة النهائية):

```bash
sudo docker compose --env-file /dev/null -f compose.yaml -p shattab-pg18-stage build api
```

البناء يحتاج اتصالًا لتنزيل صور Node/حزم npm وقد يستهلك مساحة وبيانات نقل. لا يفتح منفذًا ولا ينشئ جداول. بعد البناء، أعد فحص UID/GID للمستخدم داخل صورة API المكتملة:

```bash
sudo docker run --rm --entrypoint id shattab-api:stage node
```

لازم UID/GID يطابقوا القيم اللي تحققت منها في صورة Node الأساسية قبل إنشاء السر. لو اختلفوا، ما تشغّلش الخدمة وما توسعش الصلاحيات؛ أوقف وراجع سبب اختلاف الصورة أو البناء.

بعد تطابق الهوية، شغّل API فقط:

```bash
sudo docker compose --env-file /dev/null -f compose.yaml -p shattab-pg18-stage up -d api
```

`up -d api` يربط API بالشبكة الداخلية ويستخدم `depends_on` للتأكد إن قاعدة البيانات `healthy`. مفيش `ports` في الخدمة؛ عنوان `0.0.0.0:3000` جوه الحاوية مش ظاهر مباشرة من الإنترنت.

### 6.6 تحقق من الحالة والصلاحيات والتراجع

اعرض حالتي الخدمتين:

```bash
sudo docker compose --env-file /dev/null -f compose.yaml -p shattab-pg18-stage ps
```

المتوقع `db` و`api` بالحالة `healthy`. ده دليل اتصال قاعدة البيانات وفحص `SELECT 1` فقط. افحص بيانات تركيب الملف ومستخدم العملية من غير قراءة محتواه:

```bash
sudo docker inspect --format '{{range .Mounts}}{{if eq .Destination "/run/secrets/api_password"}}type={{.Type}} rw={{.RW}} source={{.Source}}{{end}}{{end}}' "$(sudo docker compose --env-file /dev/null -f compose.yaml -p shattab-pg18-stage ps -q api)"
```

المتوقع `type=bind rw=false` والمصدر هو ملف `api_password` المخصص. افحص إن مالك الملف `root`، ومجموعته هي الـGID الأساسي للعملية، والصلاحية بالضبط `0440` (قراءة للمالك والمجموعة فقط من غير أي كتابة أو صلاحيات للآخرين)، وإن UID وEUID للعملية مش صفر؛ `EUID` (معرّف المستخدم الفعّال في Linux) هو اللي بيحدد صلاحيات العملية وقت التنفيذ. الكود كمان بيفتح الملف للقراءة وبيقرأ بايت من غير عرضه، وبيحاول يفتحه للكتابة من غير `O_TRUNC` (خيار بيمسح محتوى الملف عند الفتح) عشان يثبت إن الكتابة مرفوضة من غير تغيير الملف. بيعرض UID/GID والصلاحية بس:

```bash
sudo docker compose --env-file /dev/null -f compose.yaml -p shattab-pg18-stage exec -T api node -e 'const fs=require("node:fs");const p="/run/secrets/api_password";const s=fs.lstatSync(p);const m=s.mode&0o777;const uid=process.getuid(),euid=process.geteuid(),gid=process.getgid();if(!s.isFile()||s.uid!==0||uid===0||euid===0||s.gid!==gid||m!==0o440)process.exit(1);const r=fs.openSync(p,fs.constants.O_RDONLY|fs.constants.O_NOFOLLOW);const b=Buffer.alloc(1);if(fs.readSync(r,b,0,1,0)!==1)process.exit(1);fs.closeSync(r);let denied=false;try{const w=fs.openSync(p,fs.constants.O_WRONLY|fs.constants.O_NOFOLLOW|fs.constants.O_NONBLOCK);fs.closeSync(w)}catch(e){denied=["EACCES","EPERM","EROFS"].includes(e.code)}if(!denied)process.exit(1);console.log(`PASS uid=${uid} euid=${euid} gid=${gid} file_gid=${s.gid} mode=${m.toString(8)} readable=true writable=false`);'
```

لازم `uid` مش صفر، و`readable=true` و`writable=false`. فشل أي تحقق يوقف العملية؛ لا توسع صلاحيات الملف. راجع `docker inspect` للتأكد إن mount (تركيب الملف داخل الحاوية) للقراءة فقط. بعد النجاح، أوقف API وحدها لو عايز تحافظ على موارد التجربة:

```bash
sudo docker compose --env-file /dev/null -f compose.yaml -p shattab-pg18-stage stop api
```

للرجوع عن تكامل API، أوقف حاويتها ثم أعد ملف Compose السابق مع إبقاء قاعدة PG18 والـ volume والسرين للتحقيق:

```bash
sudo docker compose --env-file /dev/null -f compose.yaml -p shattab-pg18-stage stop api && sudo cp -a /home/ubuntu/shattab-pg18-stage/compose.yaml.pre-api /home/ubuntu/shattab-pg18-stage/compose.yaml
```

أعد تشغيل فحص `config --quiet` على الملف المستعاد. ما تستخدمش `down -v`، أو `volume rm`، أوامر حذف، أو أي تعديل على `shattab-lab`. تراجع Compose ما يحذفش الدور أو ملف السر؛ احتفظ بيهم لحد ما تتراجع خطة إزالة معتمدة.

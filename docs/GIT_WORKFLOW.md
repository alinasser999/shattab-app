# Shattab App — Git & GitHub Workflow Standards

دليل تنظيم الفروع وإدارة الـ Pull Requests ومنع فقدان البيانات في مشروع شطب.

---

## 1. هيكل الفروع (Branch Architecture)

* **`main` (Production / Single Source of Truth)**:
  * الفرع الأساسي الموحد على GitHub.
  * لا يتم عمل Commit مباشر عليه إطلاقاً (Direct Push).
  * أي كود يدخل إليه يجب أن يمر عبر **Pull Request (PR)** مراجع ومجرب.
* **`master`**:
  * تم دمجه ومزامنته بالكامل مع `main`.
* **فروع الميزات والمهام (Feature & Task Branches)**:
  * `feat/<feature-name>`: للميزات الجديدة (مثل `feat/billing-paywall`).
  * `fix/<bug-name>`: لإصلاح الأخطاء.
  * `docs/<topic>`: للتوثيق ومواصفات الـ APIs.
  * `refactor/<target>`: لإعادة هيكلة كود بدون تغيير السلوك.
  * `codex/<task-name>`: للمهام المنفذة بواسطة وكلاء الذكاء الاصطناعي (Codex / Agents).

---

## 2. دورة حياة الـ PR (Pull Request Lifecycle)

1. **التفرع من `main` دائمًا**:
   قبل بدء أي ميزة جديدة، تأكد من سحب أحدث كود:
   ```bash
   git checkout main
   git pull origin main
   git checkout -b feat/my-new-feature
   ```

2. **التأكد من خلو مجلد العمل من الملفات المؤقتة**:
   لا تقم أبداً برفع سكريبتات تجريبية أو ملفات مؤقتة (`scratch_*`, `ref_*.png`). تأكد أن `.gitignore` يغطيها.

3. **التحقق المحلي قبل فتح PR**:
   ```bash
   flutter analyze
   flutter test
   ```

4. **فتح الـ Pull Request**:
   * قم بتوجيه الـ Base Branch إلى **`main`**.
   * املأ نموذج الـ PR (`.github/pull_request_template.md`) بالملخص ونقاط التحقق.

5. **فحص الـ CI التلقائي**:
   * يقوم GitHub Actions بالتحقق التلقائي من الكود واختباراته قبل السماح بالدمج.

---

## 3. التعامل مع الـ Stacked PRs (الـ PRs المتتابعة)

إذا كان لديك PR يعتمد على PR آخر لم يتم دمجه بعد (مثل PR #3 الذي يعتمد على PR #2):
* يكون Base فرع PR #3 هو فرع PR #2 مؤقتاً.
* بمجرد دمج PR #2 في `main`، يتم فوراً تغيير الـ Base لـ PR #3 ليصبح `main`.

---

## 4. خطة الحماية لمنع ضياع الكود (Data Loss Prevention)

* **Commit مبكر ومستمر**: لا تترك تعديلات لعدة أيام دون عمل Commit.
* **فروع حماية سحابية**: إذا كنت تعمل على ميزة كبيرة لم تكتمل بعد، ادفع الفرع إلى GitHub كـ Draft PR حتى يكون محفوظاً في السحاب.
* **تجنب الأوامر التدميرية**: تجنب استخدام `git reset --hard` أو `git clean -fd` دون التأكد من عمل Backup Branch.

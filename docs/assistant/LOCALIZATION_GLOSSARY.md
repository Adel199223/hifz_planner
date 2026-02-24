# Localization Glossary

Single source of truth for app-facing terminology across `en`, `fr`, `pt`, and `ar`.

## Purpose

Use this glossary to keep terminology consistent across Reader, planner/scheduling, companion, shell, and other screens.

## Governance Rules

1. If a term changes, update this glossary first.
2. Then update `lib/l10n/app_strings.dart`.
3. Then update screen usage and tests.
4. Avoid copying full term tables into other docs; link to this file instead.

## Reader Terminology (Quran.com overlap)

| Key | English | French | Portuguese | Arabic |
|---|---|---|---|---|
| `verse_by_verse` | Verse by Verse | Ayah par Ayah | Verso por verso | آية بآية |
| `reading` | Reading | Lecture | Lendo | القراءة |
| `surah` | Surah | Sourate | Surah | سورة |
| `verse` | Verse | Ayah | Versículo | آية |
| `juz` | Juz | Juz | Juz | جزء |
| `page` | Page | Page | Página | صفحة |
| `listen` | Listen | Écouter | Ouvir | استمع |
| `tajweed_colors` | Tajweed colors | Couleurs du Tajwid | Cores de Tajweed | ألوان التجويد |
| `tafsirs` | Tafsirs | Tafsirs | Tafsirs | تفاسير |
| `lessons` | Lessons | Leçons | Lições | فوائد |
| `reflections` | Reflections | Réflexions | Reflexões | تدبرات |
| `retry` | Retry | Réessayer | Tentar novamente | أعد المحاولة |
| `done` | Done | Fait | Feito | تم |

## Shell and App Navigation Terminology

| Key | English | French | Portuguese | Arabic |
|---|---|---|---|---|
| `reader` | Reader | Lecteur | Leitor | القارئ |
| `bookmarks` | Bookmarks | Signets | Favoritos | العلامات |
| `notes` | Notes | Notes | Notas | الملاحظات |
| `plan` | Plan | Plan | Plano | الخطة |
| `today` | Today | Aujourd'hui | Hoje | اليوم |
| `settings` | Settings | Paramètres | Configurações | الإعدادات |
| `about` | About | À propos | Sobre | حول |
| `read` | Read | Lire | Ler | اقرأ |
| `learn` | Learn | Apprendre | Aprender | تعلّم |
| `my_quran` | My Quran | Mon Coran | Meu Alcorão | قرآني |
| `quran_radio` | Quran Radio | Radio Coran | Rádio Alcorão | إذاعة القرآن |
| `reciters` | Reciters | Récitateurs | Recitadores | القرّاء |

## Scheduling and Companion Terminology

| Key | English | French | Portuguese | Arabic |
|---|---|---|---|---|
| `automatic_scheduling_title` | Automatic Scheduling | Planification automatique | Agendamento automatico | الجدولة التلقائية |
| `two_sessions_per_day` | 2 sessions per day | 2 sessions par jour | 2 sessoes por dia | جلستان يوميًا |
| `today_sessions` | Today Sessions | Sessions d'aujourd'hui | Sessoes de hoje | جلسات اليوم |
| `weekly_calendar_title` | Weekly Calendar (Next 7 Days) | Calendrier hebdomadaire (7 prochains jours) | Calendario semanal (proximos 7 dias) | التقويم الأسبوعي (الأيام السبعة القادمة) |
| `new_and_review_focus` | New + Review | Nouveau + revision | Novo + revisao | جديد + مراجعة |
| `review_only_focus` | Review-only | Revision uniquement | Apenas revisao | مراجعة فقط |
| `session_status_due_soon` | due-soon | bientot due | vence em breve | مستحقة قريبًا |
| `untimed_session_label` | Untimed | Sans heure | Sem horario | غير محددة الوقت |
| `open_companion_chain` | Open Companion Chain | Ouvrir la chaine compagnon | Abrir cadeia do companheiro | فتح سلسلة المرافق |
| `companion_progressive_reveal_title` | Progressive Reveal Chain | Chaine de revelation progressive | Cadeia de revelacao progressiva | سلسلة الكشف التدريجي |
| `companion_stage_progress` | Stage {current}/{total} | Etape {current}/{total} | Etapa {current}/{total} | المرحلة {current}/{total} |
| `companion_stage_guided_visible` | Guided visible | Guide visible | Guiado visivel | موجّه ظاهر |
| `companion_stage_cued_recall` | Cued recall | Rappel avec indice | Recordacao por pista | استرجاع بالمفتاح |
| `companion_stage_hidden_reveal` | Hidden reveal | Revelation cachee | Revelacao oculta | كشف مخفي |
| `companion_skip_stage_button` | Skip Stage | Passer l'etape | Pular etapa | تخطي المرحلة |
| `companion_skip_stage_title` | Skip current stage? | Passer l'etape en cours ? | Pular etapa atual? | تخطي المرحلة الحالية؟ |
| `companion_skip_stage_confirm` | Skip | Passer | Pular | تخطي |
| `companion_active_hint_label` | Active hint | Indice actif | Dica ativa | التلميح النشط |
| `companion_play_current_ayah` | Play current ayah | Ecouter l'ayah actuelle | Ouvir ayah atual | تشغيل الآية الحالية |
| `companion_autoplay_next_ayah` | Autoplay next ayah | Lecture auto ayah suivante | Reproducao auto da proxima ayah | تشغيل تلقائي للآية التالية |
| `companion_autoplay_on` | Autoplay on | Lecture auto activee | Reproducao auto ativada | التشغيل التلقائي مفعل |
| `companion_autoplay_off` | Autoplay off | Lecture auto desactivee | Reproducao auto desativada | التشغيل التلقائي متوقف |
| `companion_record_start` | Record / Start | Enregistrer / Demarrer | Gravar / Iniciar | تسجيل / بدء |
| `companion_stage1_mode_label` | Stage 1 mode | Mode etape 1 | Modo da etapa 1 | وضع المرحلة 1 |
| `companion_stage1_mode_model_echo` | Model + Echo | Modele + echo | Modelo + eco | نموذج + ترديد |
| `companion_stage1_mode_cold_probe` | Cold Probe | Sonde a froid | Sondagem fria | اختبار بارد |
| `companion_stage1_mode_correction` | Correction | Correction | Correcao | تصحيح |
| `companion_stage1_mode_spaced_reprobe` | Spaced Re-probe | Re-sondage espace | Re-sondagem espacada | إعادة اختبار متباعدة |
| `companion_stage1_mode_checkpoint` | Checkpoint | Point de controle | Ponto de controle | نقطة تحقق |
| `companion_stage1_mode_cumulative` | Cumulative Check | Verification cumulative | Verificacao cumulativa | تحقق تراكمي |
| `companion_stage1_auto_check_title` | Micro-check | Micro-verification | Microverificacao | تحقق مصغر |
| `companion_stage1_correction_action` | Play Correction | Lancer la correction | Reproduzir correcao | تشغيل التصحيح |
| `companion_stage1_recite_now` | Recite now. | Recite maintenant. | Recite agora. | رتل الآن. |
| `companion_stage1_recite_now_hidden_prompt` | Recite now (text hidden). | Recite maintenant (texte cache). | Recite agora (texto oculto). | رتل الآن (النص مخفي). |
| `companion_stage1_correction_required_message` | Correction playback is required before the next cold attempt. | La correction est requise avant le prochain essai a froid. | A correcao e obrigatoria antes da proxima tentativa fria. | يلزم تشغيل التصحيح قبل المحاولة الباردة التالية. |
| `companion_stage1_auto_check_required_selection` | Select an answer for the micro-check first. | Selectionnez une reponse pour la micro-verification d'abord. | Selecione uma resposta para a microverificacao primeiro. | اختر إجابة للتحقق المصغر أولاً. |
| `companion_stage1_hint_locked_message` | Hints unlock after the first cold attempt. | Les indices se debloquent apres la premiere tentative a froid. | As dicas desbloqueiam apos a primeira tentativa fria. | تُفتح التلميحات بعد أول محاولة باردة. |
| `companion_stage1_weak_verses` | Weak verses flagged for reinforcement: {count} | Versets faibles marques pour renforcement : {count} | Versos fracos marcados para reforco: {count} | تم تمييز الآيات الضعيفة للتقوية: {count} |
| `companion_stage2_mode_label` | Stage 2 mode | Mode etape 2 | Modo da etapa 2 | وضع المرحلة 2 |
| `companion_stage2_mode_minimal_cue_recall` | Minimal-Cue Recall | Rappel a indice minimal | Recordacao com pista minima | استرجاع بأقل تلميح |
| `companion_stage2_mode_discrimination` | Discrimination | Discrimination | Discriminacao | تمييز |
| `companion_stage2_mode_linking` | Linking (Rabt-lite) | Liaison (rabt leger) | Ligacao (rabt leve) | ربط (خفيف) |
| `companion_stage2_mode_correction` | Correction | Correction | Correcao | تصحيح |
| `companion_stage2_mode_checkpoint` | Checkpoint | Point de controle | Ponto de controle | نقطة تحقق |
| `companion_stage2_mode_remediation` | Remediation | Remediation | Remediacao | معالجة |
| `companion_stage2_recite_now` | Recite with minimal cue. | Recite avec indice minimal. | Recite com pista minima. | رتل بأقل تلميح. |
| `companion_stage2_correction_required_message` | Correction playback is required before the next Stage-2 attempt. | La correction est requise avant le prochain essai de l'etape 2. | A correcao e obrigatoria antes da proxima tentativa da etapa 2. | يلزم تشغيل التصحيح قبل محاولة المرحلة 2 التالية. |
| `companion_stage2_correction_action` | Play Stage-2 Correction | Lancer la correction etape 2 | Reproduzir correcao da etapa 2 | تشغيل تصحيح المرحلة 2 |
| `companion_stage3_mode_label` | Stage 3 mode | Mode etape 3 | Modo da etapa 3 | وضع المرحلة 3 |
| `companion_stage3_mode_weak_prelude` | Weak Prelude | Prelude faible | Preludio fraco | تمهيد ضعيف |
| `companion_stage3_mode_hidden_recall` | Hidden Recall | Rappel cache | Recordacao oculta | استرجاع مخفي |
| `companion_stage3_mode_linking` | Linking | Liaison | Ligacao | ربط |
| `companion_stage3_mode_discrimination` | Discrimination | Discrimination | Discriminacao | تمييز |
| `companion_stage3_mode_correction` | Correction | Correction | Correcao | تصحيح |
| `companion_stage3_mode_checkpoint` | Checkpoint | Point de controle | Ponto de controle | نقطة تحقق |
| `companion_stage3_mode_remediation` | Remediation | Remediation | Remediacao | معالجة |
| `companion_stage3_recite_now` | Recite from hidden recall. | Recite depuis le rappel cache. | Recite a partir da recordacao oculta. | رتل من الاسترجاع المخفي. |
| `companion_stage3_correction_required_message` | Correction playback is required before the next Stage-3 attempt. | La correction est requise avant le prochain essai de l'etape 3. | A correcao e obrigatoria antes da proxima tentativa da etapa 3. | يلزم تشغيل التصحيح قبل محاولة المرحلة 3 التالية. |
| `companion_stage3_correction_action` | Play Stage-3 Correction | Lancer la correction etape 3 | Reproduzir correcao da etapa 3 | تشغيل تصحيح المرحلة 3 |
| `companion_stage3_weak_prelude_banner` | Weak-prelude active: {count} verses must pass before normal hidden flow. | Prelude des versets faibles active : {count} versets doivent reussir avant le flux cache normal. | Preludio fraco ativo: {count} versos devem passar antes do fluxo oculto normal. | تم تفعيل تمهيد الآيات الضعيفة: يجب نجاح {count} آيات قبل التدفق المخفي الطبيعي. |
| `companion_hint_button` | Hint | Indice | Dica | تلميح |
| `companion_repeat_button` | Repeat | Repeter | Repetir | إعادة |
| `companion_mark_correct` | Mark correct | Marquer correct | Marcar correto | تحديد كصحيح |
| `companion_mark_incorrect` | Mark incorrect | Marquer incorrect | Marcar incorreto | تحديد كغير صحيح |
| `companion_session_complete` | Session complete | Session terminee | Sessao concluida | اكتملت الجلسة |
| `companion_summary_strength` | Average retrieval strength: {value} | Force moyenne de recuperation : {value} | Forca media de recuperacao: {value} | متوسط قوة الاسترجاع: {value} |

## Known Intentional Duplicates

- `Surah` and `Juz` intentionally remain `Surah`/`Juz` in Portuguese and French usage for Quran-specific terminology.
- `Tafsirs` intentionally stays `Tafsirs` in English/French/Portuguese.

## Related Workflow

- `docs/assistant/workflows/LOCALIZATION_WORKFLOW.md`
- `docs/assistant/workflows/SCHEDULING_COMPANION_WORKFLOW.md`

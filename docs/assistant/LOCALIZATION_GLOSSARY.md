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

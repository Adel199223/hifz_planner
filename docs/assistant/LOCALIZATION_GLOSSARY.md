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
| `download` | Download | Télécharger | Baixar | تنزيل |
| `remove_download` | Remove download | Supprimer le téléchargement | Remover download | إزالة التنزيل |
| `experience` | Experience | Expérience | Experiência | التجربة |
| `word_by_word` | Word By Word | Mot à mot | Palavra por palavra | كلمة بكلمة |
| `show_verse_translations` | Show verse translations | Afficher les traductions des ayahs | Mostrar traduções dos versículos | إظهار ترجمات الآيات |
| `show_word_tooltips` | Show word tooltips | Afficher les infobulles des mots | Mostrar dicas das palavras | إظهار تلميحات الكلمات |
| `highlight_hovered_words` | Highlight hovered words | Surligner les mots au survol | Destacar palavras ao passar o mouse | تمييز الكلمات عند المرور عليها |
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
| `stage4_due_section_title` | Stage-4 delayed checks | Verifications differees etape 4 | Verificacoes adiadas etapa 4 | تحققات المرحلة 4 المؤجلة |
| `stage4_no_due_items` | No Stage-4 delayed checks are due. | Aucune verification differee etape 4 due. | Nenhuma verificacao adiada da etapa 4 pendente. | لا توجد تحققات مرحلة 4 مؤجلة مستحقة. |
| `stage4_tier_summary` | Tiers - Emerging: {emerging}, Ready: {ready}, Stable: {stable}, Maintained: {maintained} | Paliers - Emergente: {emerging}, Prete: {ready}, Stable: {stable}, En maintien: {maintained} | Niveis - Emergente: {emerging}, Pronta: {ready}, Estavel: {stable}, Em manutencao: {maintained} | المستويات - ناشئة: {emerging}، جاهزة: {ready}، مستقرة: {stable}، قيد الصيانة: {maintained} |
| `lifecycle_tier_emerging` | Emerging | Emergente | Emergente | ناشئة |
| `lifecycle_tier_ready` | Ready | Prete | Pronta | جاهزة |
| `lifecycle_tier_stable` | Stable | Stable | Estavel | مستقرة |
| `lifecycle_tier_maintained` | Maintained | En maintien | Em manutencao | قيد الصيانة |
| `review_lifecycle_promoted_to_maintained` | This unit moved to maintained. | Cette unite est passee en maintien. | Esta unidade passou para manutencao. | انتقلت هذه الوحدة إلى مستوى الصيانة. |
| `review_lifecycle_demoted_to_stable` | This unit moved back to stable. | Cette unite est redescendue a stable. | Esta unidade voltou para estavel. | عادت هذه الوحدة إلى مستوى الاستقرار. |
| `review_lifecycle_demoted_to_ready` | This unit moved back to ready. | Cette unite est redescendue a prete. | Esta unidade voltou para pronta. | عادت هذه الوحدة إلى مستوى الجاهزية. |
| `stage4_due_kind_pre_sleep_optional` | Optional pre-sleep check | Verification optionnelle avant sommeil | Verificacao opcional antes de dormir | تحقق اختياري قبل النوم |
| `stage4_due_kind_next_day_required` | Mandatory next-day check | Verification obligatoire le lendemain | Verificacao obrigatoria no dia seguinte | تحقق إلزامي في اليوم التالي |
| `stage4_due_kind_retry_required` | Mandatory retry check | Verification obligatoire de nouvelle tentative | Verificacao obrigatoria de nova tentativa | تحقق إعادة إلزامي |
| `stage4_due_item_summary` | {dueKind} - overdue by {overdueDays} day(s) - unresolved: {unresolvedCount} | {dueKind} - retard de {overdueDays} jour(s) - non resolu: {unresolvedCount} | {dueKind} - atrasado ha {overdueDays} dia(s) - nao resolvido: {unresolvedCount} | {dueKind} - متأخر {overdueDays} يوم/أيام - غير محلول: {unresolvedCount} |
| `stage4_open_action` | Open Stage-4 Check | Ouvrir verification etape 4 | Abrir verificacao da etapa 4 | فتح تحقق المرحلة 4 |
| `stage4_override_new_action` | Start new anyway | Demarrer nouveau quand meme | Iniciar novo mesmo assim | ابدأ الجديد رغم ذلك |
| `stage4_override_dialog_title` | Mandatory Stage-4 checks due | Verifications obligatoires etape 4 dues | Verificacoes obrigatorias da etapa 4 pendentes | تحققات المرحلة 4 الإلزامية مستحقة |
| `stage4_override_dialog_message` | Mandatory Stage-4 delayed checks are due. Continue anyway and log override? | Des verifications differees obligatoires de l'etape 4 sont dues. Continuer et enregistrer le contournement ? | Verificacoes adiadas obrigatorias da etapa 4 estao pendentes. Continuar e registrar excecao? | توجد تحققات مرحلة 4 مؤجلة إلزامية. هل تتابع مع تسجيل التجاوز؟ |
| `stage4_override_dialog_confirm` | Override | Contourner | Ignorar bloqueio | تجاوز |
| `stage4_override_applied` | New memorization override recorded for today. | Contournement de nouvelle memorisation enregistre pour aujourd'hui. | Excecao de nova memorizacao registrada para hoje. | تم تسجيل تجاوز حفظ جديد لليوم. |
| `stage4_override_failed` | Could not record override right now. | Impossible d'enregistrer le contournement maintenant. | Nao foi possivel registrar a excecao agora. | تعذر تسجيل التجاوز الآن. |
| `companion_skip_stage_button` | Skip Stage | Passer l'etape | Pular etapa | تخطي المرحلة |
| `companion_skip_stage_title` | Skip current stage? | Passer l'etape en cours ? | Pular etapa atual? | تخطي المرحلة الحالية؟ |
| `companion_skip_stage_confirm` | Skip | Passer | Pular | تخطي |
| `companion_active_hint_label` | Active hint | Indice actif | Dica ativa | التلميح النشط |
| `companion_meaning_cue_loading` | Loading meaning cue... | Chargement de l'indice de sens... | Carregando dica de significado... | جاري تحميل إشارة المعنى... |
| `translation_label` | Translation: {label} | Traduction : {label} | Tradução: {label} | الترجمة: {label} |
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
| `companion_stage4_mode_label` | Stage 4 mode | Mode etape 4 | Modo da etapa 4 | وضع المرحلة 4 |
| `companion_stage4_mode_cold_start` | Cold Start | Demarrage a froid | Inicio frio | بداية باردة |
| `companion_stage4_mode_random_start` | Random Start | Depart aleatoire | Inicio aleatorio | بداية عشوائية |
| `companion_stage4_mode_linking` | Linking | Liaison | Ligacao | ربط |
| `companion_stage4_mode_discrimination` | Discrimination | Discrimination | Discriminacao | تمييز |
| `companion_stage4_mode_correction` | Correction | Correction | Correcao | تصحيح |
| `companion_stage4_mode_checkpoint` | Checkpoint | Point de controle | Ponto de controle | نقطة تحقق |
| `companion_stage4_mode_remediation` | Remediation | Remediation | Remediacao | معالجة |
| `companion_stage4_recite_now` | Recite from delayed hidden recall. | Recite depuis un rappel cache differe. | Recite a partir de recordacao oculta adiada. | رتل من استرجاع مخفي مؤجل. |
| `companion_stage4_correction_required_message` | Stage-4 correction exposure is required before retry. | L'exposition de correction etape 4 est requise avant de reessayer. | A exposicao de correcao da etapa 4 e obrigatoria antes de tentar novamente. | يلزم عرض تصحيح المرحلة 4 قبل إعادة المحاولة. |
| `companion_stage4_correction_action` | Play Stage-4 Correction | Lancer la correction etape 4 | Reproduzir correcao da etapa 4 | تشغيل تصحيح المرحلة 4 |
| `companion_stage4_due_banner` | Stage-4 due type: {dueKind} | Type d'echeance etape 4 : {dueKind} | Tipo de vencimento da etapa 4: {dueKind} | نوع استحقاق المرحلة 4: {dueKind} |
| `companion_stage4_unresolved_targets` | Unresolved Stage-4 targets: {count} | Cibles etape 4 non resolues : {count} | Alvos nao resolvidos da etapa 4: {count} | أهداف المرحلة 4 غير المحلولة: {count} |
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

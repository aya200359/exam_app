-- ============================================
-- PART 1: DEPARTMENTS (7 departments)
-- ============================================
INSERT INTO departements (nom) VALUES 
('Informatique'),
('Mathématiques'),
('Physique'),
('Chimie'),
('Économie'),
('Droit'),
('Médecine');

-- ============================================
-- PART 2: FORMATIONS (70 TOTAL - 10 per department)
-- ============================================
INSERT INTO formations (nom, id_dept) VALUES
-- Informatique (10 formations - 5 licence, 5 master)
('Licence Informatique', 1),
('Licence Systèmes et Réseaux', 1),
('Licence Développement Web', 1),
('Licence Big Data', 1),
('Licence Réalité Virtuelle', 1),
('Master Génie Logiciel', 1),
('Master Intelligence Artificielle', 1),
('Master Cybersécurité', 1),
('Master Cloud Computing', 1),
('Master IoT', 1),

-- Économie (10 formations - 5 licence, 5 master)
('Licence Économie', 5),
('Licence Marketing', 5),
('Licence Banque', 5),
('Licence RH', 5),
('Licence Commerce International', 5),
('Master Finance', 5),
('Master Audit', 5),
('Master Management', 5),
('Master Supply Chain', 5),
('Master Entrepreneuriat', 5),

-- Droit (10 formations - 5 licence, 5 master)
('Licence Droit Privé', 6),
('Licence Droit Public', 6),
('Licence Sciences Po', 6),
('Licence Criminologie', 6),
('Licence Droit Fiscal', 6),
('Master Droit des Affaires', 6),
('Master Droit International', 6),
('Master Droit Notarial', 6),
('Master Droit Social', 6),
('Master Droit Européen', 6),

-- Médecine (10 formations - 5 licence, 5 master)
('Licence Médecine', 7),
('Licence Pharmacie', 7),
('Licence Dentaire', 7),
('Licence Kinésithérapie', 7),
('Licence Sage-femme', 7),
('Master Chirurgie', 7),
('Master Pédiatrie', 7),
('Master Cardiologie', 7),
('Master Neurologie', 7),
('Master Radiologie', 7),

-- Mathématiques (10 formations - 5 licence, 5 master)
('Licence Mathématiques', 2),
('Licence Statistiques', 2),
('Licence Math-Info', 2),
('Licence Actuariat', 2),
('Licence Modélisation', 2),
('Master Mathématiques Appliquées', 2),
('Master Data Science', 2),
('Master Recherche Opérationnelle', 2),
('Master Cryptographie', 2),
('Master Mathématiques Fondamentales', 2),

-- Physique (10 formations - 5 licence, 5 master)
('Licence Physique', 3),
('Licence Énergie', 3),
('Licence Mécanique', 3),
('Licence Nanotechnologies', 3),
('Licence Acoustique', 3),
('Master Physique Quantique', 3),
('Master Matériaux', 3),
('Master Astrophysique', 3),
('Master Physique Médicale', 3),
('Master Optique', 3),

-- Chimie (10 formations - 5 licence, 5 master)
('Licence Chimie', 4),
('Licence Biochimie', 4),
('Licence Chimie Analytique', 4),
('Licence Chimie Environnementale', 4),
('Licence Chimie Industrielle', 4),
('Master Chimie Organique', 4),
('Master Génie Chimique', 4),
('Master Chimie Pharmaceutique', 4),
('Master Chimie des Matériaux', 4),
('Master Chimie Fine', 4);

-- ============================================
-- PART 3: MODULES (6-9 modules per year per formation)
-- ============================================
-- Generate modules: 6-9 per year for each formation
INSERT INTO modules (nom, credits, id_formation, annee)
WITH RECURSIVE years AS (
    SELECT 1 as year_num, 'L1' as annee UNION
    SELECT 2, 'L2' UNION
    SELECT 3, 'L3' UNION
    SELECT 4, 'M1' UNION
    SELECT 5, 'M2'
),
modules_per_year AS (
    SELECT 
        f.id_formation,
        CASE 
            WHEN f.nom LIKE 'Licence%' THEN y.annee
            WHEN f.nom LIKE 'Master%' AND y.year_num >= 4 THEN y.annee
            ELSE NULL
        END as annee,
        -- Random number of modules between 6 and 9
        FLOOR(6 + RAND() * 4) as num_modules
    FROM formations f
    CROSS JOIN years y
    WHERE (f.nom LIKE 'Licence%' AND y.year_num <= 3)
       OR (f.nom LIKE 'Master%' AND y.year_num >= 4)
),
module_numbers AS (
    SELECT 1 as n UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION SELECT 5 UNION 
    SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9
)
SELECT 
    CONCAT('MOD_', mp.annee, '_F', mp.id_formation, '_', mn.n),
    5,
    mp.id_formation,
    mp.annee
FROM modules_per_year mp
CROSS JOIN module_numbers mn
WHERE mn.n <= mp.num_modules;

-- ============================================
-- PART 4: PROFESSEURS
-- ============================================

INSERT INTO professeurs (nom, specialite, id_dept)
SELECT 
    CONCAT('Prof_', LPAD(n, 4, '0')) as nom,
    CONCAT('Specialite_', 
           CASE d.nom
               WHEN 'Informatique' THEN 'INFO'
               WHEN 'Mathématiques' THEN 'MATH'
               WHEN 'Physique' THEN 'PHYS'
               WHEN 'Chimie' THEN 'CHIM'
               WHEN 'Économie' THEN 'ECO'
               WHEN 'Droit' THEN 'DROIT'
               WHEN 'Médecine' THEN 'MED'
               ELSE 'GEN'
           END,
           '_', LPAD(FLOOR(1 + RAND() * 20), 2, '0')) as specialite,
    d.id_dept
FROM departements d
CROSS JOIN (
    SELECT 
        (a.n + b.n*10) as n
    FROM 
        (SELECT 0 as n UNION SELECT 1 UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION SELECT 5 UNION SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9) a,
        (SELECT 0 as n UNION SELECT 1 UNION SELECT 2 UNION SELECT 3) b  -- 10 × 4 = 40 numbers
    WHERE (a.n + b.n*10) > 0 AND (a.n + b.n*10) <= 34  -- Limit to 34 per department
) numbers
ORDER BY RAND();

-- ============================================
-- PART 2: DYNAMIC STUDENT GENERATION
-- ============================================

INSERT INTO etudiants (nom, prenom, annee, id_formation)
WITH RECURSIVE 
-- All formation-year combinations we want to create
formation_years AS (
    SELECT 
        f.id_formation,
        y.annee,
        -- Number of groups per formation-year (5 for license, 3 for master)
        CASE 
            WHEN y.annee IN ('L1', 'L2', 'L3') THEN 5  -- 5 groups × 30 = 150 students
            WHEN y.annee IN ('M1', 'M2') THEN 3        -- 3 groups × 30 = 90 students
        END as groups_per_fy,
        -- Total students per formation-year
        CASE 
            WHEN y.annee IN ('L1', 'L2', 'L3') THEN 5 * 30  -- 150 students
            WHEN y.annee IN ('M1', 'M2') THEN 3 * 30        -- 90 students
        END as students_per_fy
    FROM formations f
    CROSS JOIN (SELECT 'L1' as annee 
                UNION SELECT 'L2' 
                UNION SELECT 'L3' 
                UNION SELECT 'M1' 
                UNION SELECT 'M2') y
    WHERE f.id_formation BETWEEN 1 AND 42  -- All 42 formations
),
-- Generate sequence numbers for students within each formation-year
student_numbers AS (
    SELECT 
        fy.id_formation,
        fy.annee,
        n.student_num,
        -- Calculate which group this student will be in (1-based)
        CEIL(n.student_num / 30.0) as group_num,
        -- Calculate position within group (1-30)
        CASE 
            WHEN n.student_num % 30 = 0 THEN 30
            ELSE n.student_num % 30
        END as position_in_group
    FROM formation_years fy
    CROSS JOIN (
        WITH RECURSIVE numbers AS (
            SELECT 1 AS n
            UNION ALL
            SELECT n + 1 FROM numbers WHERE n < 150  -- Max 150 students per formation-year
        )
        SELECT n as student_num FROM numbers
    ) n
    WHERE n.student_num <= fy.students_per_fy
)
SELECT
    -- Student code: E + formation + year + position (e.g., E-F01-L1-001)
    CONCAT('E-F', 
           LPAD(sn.id_formation, 2, '0'), 
           '-', 
           sn.annee, 
           '-', 
           LPAD(sn.student_num, 3, '0')) as nom,
    -- First name
    CONCAT('Prenom_', 
           LPAD(ROW_NUMBER() OVER (ORDER BY sn.id_formation, sn.annee, sn.student_num), 
                5, '0')) as prenom,
    sn.annee,
    sn.id_formation
FROM student_numbers sn
ORDER BY sn.id_formation, sn.annee, sn.student_num;

-- Check total students generated
SELECT COUNT(*) as total_etudiants FROM etudiants;

-- Check distribution
SELECT 
    annee,
    COUNT(*) as nombre_etudiants,
    COUNT(*) / COUNT(DISTINCT id_formation) as avg_per_formation
FROM etudiants
GROUP BY annee
ORDER BY annee;

-- ============================================
-- PART 3: GROUPES GENERATION (Minimum 5 groups per year)
-- ============================================
-- Create groups for ALL formation-year combinations (even with 0 students)

INSERT INTO groupes (code_groupe, id_formation, annee)
WITH RECURSIVE 
-- Get ALL formations and their possible years
all_formations_years AS (
    SELECT 
        f.id_formation,
        y.annee,
        CASE 
            WHEN f.nom LIKE 'Licence%' THEN 5  -- Minimum 5 groups for Licence
            WHEN f.nom LIKE 'Master%' THEN 3   -- Minimum 3 groups for Master
        END as min_groups
    FROM formations f
    CROSS JOIN (
        SELECT 'L1' as annee UNION ALL
        SELECT 'L2' UNION ALL
        SELECT 'L3' UNION ALL
        SELECT 'M1' UNION ALL
        SELECT 'M2'
    ) y
    WHERE (f.nom LIKE 'Licence%' AND y.annee IN ('L1', 'L2', 'L3'))
       OR (f.nom LIKE 'Master%' AND y.annee IN ('M1', 'M2'))
),
-- Get actual student count per formation-year
student_counts AS (
    SELECT 
        id_formation,
        annee,
        COUNT(*) as student_count
    FROM etudiants
    GROUP BY id_formation, annee
),
-- Calculate needed groups: MINIMUM 5/3 groups OR based on student count (target 25-30 per group)
needed_groups AS (
    SELECT 
        afy.id_formation,
        afy.annee,
        GREATEST(
            afy.min_groups, 
            CEIL(COALESCE(sc.student_count, 0) / 27.5)  -- Target 25-30 students per group
        ) as groups_needed
    FROM all_formations_years afy
    LEFT JOIN student_counts sc ON afy.id_formation = sc.id_formation AND afy.annee = sc.annee
),
-- Sequence for group numbers (1 to 20 max)
seq AS (
    SELECT 1 AS n 
    UNION ALL 
    SELECT n + 1 FROM seq WHERE n < 20
)
SELECT 
    CONCAT(ng.annee, 
           '-F', 
           LPAD(ng.id_formation, 3, '0'), 
           '-G', 
           LPAD(seq.n, 2, '0')) as code_groupe,
    ng.id_formation,
    ng.annee
FROM needed_groups ng
JOIN seq ON seq.n <= ng.groups_needed
ORDER BY ng.id_formation, ng.annee, seq.n;

-- Check groups created
SELECT COUNT(*) as total_groupes FROM groupes;

-- ============================================
-- PART 4: ASSIGN STUDENTS TO GROUPS (Round-robin distribution)
-- ============================================
SET SQL_SAFE_UPDATES = 0;

-- Assign students to groups using round-robin within each formation-year
UPDATE etudiants e
JOIN (
    -- Rank students within each formation-year
    SELECT 
        id_etudiant,
        id_formation,
        annee,
        ROW_NUMBER() OVER (PARTITION BY id_formation, annee ORDER BY id_etudiant) as student_rank
    FROM etudiants
) ranked_students ON e.id_etudiant = ranked_students.id_etudiant
JOIN (
    -- Rank groups within each formation-year with count
    SELECT 
        g.id_groupe,
        g.id_formation,
        g.annee,
        ROW_NUMBER() OVER (PARTITION BY g.id_formation, g.annee ORDER BY g.id_groupe) as group_rank,
        COUNT(*) OVER (PARTITION BY g.id_formation, g.annee) as total_groups
    FROM groupes g
) ranked_groups ON ranked_students.id_formation = ranked_groups.id_formation 
                AND ranked_students.annee = ranked_groups.annee
                -- Round-robin distribution
                AND ranked_groups.group_rank = 
                    ((ranked_students.student_rank - 1) % ranked_groups.total_groups) + 1
SET e.id_groupe = ranked_groups.id_groupe;

-- Update group sizes
UPDATE groupes g
SET effectif = (
    SELECT COUNT(*) 
    FROM etudiants e 
    WHERE e.id_groupe = g.id_groupe
);

-- Verify group sizes
SELECT 
    'Group Size Statistics' as report,
    COUNT(*) as total_groups,
    MIN(effectif) as min_size,
    MAX(effectif) as max_size,
    ROUND(AVG(effectif), 2) as avg_size,
    COUNT(CASE WHEN effectif BETWEEN 20 AND 30 THEN 1 END) as groups_20_30,
    ROUND(COUNT(CASE WHEN effectif BETWEEN 20 AND 30 THEN 1 END) * 100.0 / COUNT(*), 2) as percentage_good_size
FROM groupes
WHERE effectif > 0;

SET SQL_SAFE_UPDATES = 1;

-- ============================================
-- PART 8: INSCRIPTIONS (Enroll students in their modules)
-- ============================================
INSERT INTO inscriptions (id_etudiant, id_module)
SELECT e.id_etudiant, m.id_module
FROM etudiants e
JOIN modules m ON e.id_formation = m.id_formation AND e.annee = m.annee;

-- ============================================
-- PART 9: LIEUX EXAMEN (Exam rooms)
-- ============================================
INSERT INTO lieux_examen (nom, capacite, type, batiment) VALUES 
-- Small rooms (50 rooms, capacity 20)
('Salle A101', 20, 'salle', 'Bâtiment A'),
('Salle A102', 20, 'salle', 'Bâtiment A'),
('Salle A103', 20, 'salle', 'Bâtiment A'),
('Salle A104', 20, 'salle', 'Bâtiment A'),
('Salle A105', 20, 'salle', 'Bâtiment A'),
('Salle A106', 20, 'salle', 'Bâtiment A'),
('Salle A107', 20, 'salle', 'Bâtiment A'),
('Salle A108', 20, 'salle', 'Bâtiment A'),
('Salle A109', 20, 'salle', 'Bâtiment A'),
('Salle A110', 20, 'salle', 'Bâtiment A'),
('Salle B201', 20, 'salle', 'Bâtiment B'),
('Salle B202', 20, 'salle', 'Bâtiment B'),
('Salle B203', 20, 'salle', 'Bâtiment B'),
('Salle B204', 20, 'salle', 'Bâtiment B'),
('Salle B205', 20, 'salle', 'Bâtiment B'),
('Salle B206', 20, 'salle', 'Bâtiment B'),
('Salle B207', 20, 'salle', 'Bâtiment B'),
('Salle B208', 20, 'salle', 'Bâtiment B'),
('Salle B209', 20, 'salle', 'Bâtiment B'),
('Salle B210', 20, 'salle', 'Bâtiment B'),
('Salle C301', 20, 'salle', 'Bâtiment C'),
('Salle C302', 20, 'salle', 'Bâtiment C'),
('Salle C303', 20, 'salle', 'Bâtiment C'),
('Salle C304', 20, 'salle', 'Bâtiment C'),
('Salle C305', 20, 'salle', 'Bâtiment C'),
('Salle C306', 20, 'salle', 'Bâtiment C'),
('Salle C307', 20, 'salle', 'Bâtiment C'),
('Salle C308', 20, 'salle', 'Bâtiment C'),
('Salle C309', 20, 'salle', 'Bâtiment C'),
('Salle C310', 20, 'salle', 'Bâtiment C'),
('Salle D401', 20, 'salle', 'Bâtiment D'),
('Salle D402', 20, 'salle', 'Bâtiment D'),
('Salle D403', 20, 'salle', 'Bâtiment D'),
('Salle D404', 20, 'salle', 'Bâtiment D'),
('Salle D405', 20, 'salle', 'Bâtiment D'),
('Salle D406', 20, 'salle', 'Bâtiment D'),
('Salle D407', 20, 'salle', 'Bâtiment D'),
('Salle D408', 20, 'salle', 'Bâtiment D'),
('Salle D409', 20, 'salle', 'Bâtiment D'),
('Salle D410', 20, 'salle', 'Bâtiment D'),
('Salle E501', 20, 'salle', 'Bâtiment E'),
('Salle E502', 20, 'salle', 'Bâtiment E'),
('Salle E503', 20, 'salle', 'Bâtiment E'),
('Salle E504', 20, 'salle', 'Bâtiment E'),
('Salle E505', 20, 'salle', 'Bâtiment E'),
('Salle E506', 20, 'salle', 'Bâtiment E'),
('Salle E507', 20, 'salle', 'Bâtiment E'),
('Salle E508', 20, 'salle', 'Bâtiment E'),
('Salle E509', 20, 'salle', 'Bâtiment E'),
('Salle E510', 20, 'salle', 'Bâtiment E'),

-- Amphitheaters (15 amphis, capacity 100-500)
('Amphi Central', 500, 'amphi', 'Bâtiment Principal'),
('Amphi Grand', 400, 'amphi', 'Bâtiment Principal'),
('Amphi Nord', 300, 'amphi', 'Bâtiment Nord'),
('Amphi Sud', 300, 'amphi', 'Bâtiment Sud'),
('Amphi Est', 250, 'amphi', 'Bâtiment Est'),
('Amphi Ouest', 250, 'amphi', 'Bâtiment Ouest'),
('Amphi Sciences', 200, 'amphi', 'Bâtiment Sciences'),
('Amphi Lettres', 200, 'amphi', 'Bâtiment Lettres'),
('Amphi Droit', 150, 'amphi', 'Bâtiment Droit'),
('Amphi Médecine', 150, 'amphi', 'Bâtiment Médecine'),
('Amphi Économie', 200, 'amphi', 'Bâtiment Économie'),
('Amphi Informatique', 300, 'amphi', 'Bâtiment Informatique'),
('Amphi Conférence A', 100, 'amphi', 'Bâtiment Conférence'),
('Amphi Conférence B', 100, 'amphi', 'Bâtiment Conférence'),
('Amphi Conférence C', 100, 'amphi', 'Bâtiment Conférence');
-- ============================================
-- PART 10: EXAMENS (One exam per module, 90 minutes)
-- ============================================
INSERT INTO examens (id_module, duree_minutes)
SELECT id_module, 90 FROM modules;

SET SQL_SAFE_UPDATES = 1;
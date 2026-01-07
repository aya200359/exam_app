import mysql.connector
import time
import sys
from collections import defaultdict

start_time = time.time()

conn = None
cursor = None

try:
    # =========================
    # 1️⃣ Database connection
    # =========================
    conn = mysql.connector.connect(
        host="localhost",
        user="root",
        password="bac@2021",
        database="exam_timetabling"
    )
    cursor = conn.cursor(dictionary=True)

    # =========================
    # 2️⃣ Load scheduled exams
    # =========================
    cursor.execute("""
        SELECT 
            p.id_planning,
            p.id_examen,
            c.date,
            f.id_dept
        FROM planning_examens p
        JOIN examens e    ON e.id_examen = p.id_examen
        JOIN modules m    ON m.id_module = e.id_module
        JOIN formations f ON f.id_formation = m.id_formation
        JOIN creneaux c   ON c.id_creneau = p.id_creneau
        ORDER BY c.date
    """)
    scheduled_exams = cursor.fetchall()

    # =========================
    # 3️⃣ Load professors by department
    # =========================
    cursor.execute("""
        SELECT id_prof, id_dept
        FROM professeurs
    """)

    professors_by_dept = defaultdict(list)
    for row in cursor.fetchall():
        professors_by_dept[row["id_dept"]].append(row["id_prof"])

    # =========================
    # 4️⃣ Existing workload
    # =========================
    cursor.execute("""
        SELECT s.id_prof, c.date
        FROM surveillances s
        JOIN planning_examens p ON p.id_planning = s.id_planning
        JOIN creneaux c ON c.id_creneau = p.id_creneau
    """)

    prof_exam_count = defaultdict(int)
    for row in cursor.fetchall():
        prof_exam_count[(row["id_prof"], row["date"])] += 1

    # =========================
    # 5️⃣ Assign professors
    # =========================
    insert_rows = []

    for exam in scheduled_exams:
        planning_id = exam["id_planning"]
        exam_id = exam["id_examen"]
        exam_date = exam["date"]
        dept_id = exam["id_dept"]

        assigned = False

        for prof_id in professors_by_dept.get(dept_id, []):
            if prof_exam_count.get((prof_id, exam_date), 0) < 2:  # ⬅️ max 2 surveillances / jour
                insert_rows.append((prof_id, planning_id))
                prof_exam_count[(prof_id, exam_date)] += 1
                assigned = True
                break

        if not assigned:
            print(f"⚠️ No professor available for exam {exam_id} on {exam_date}")

    # =========================
    # 6️⃣ Insert surveillances
    # =========================
    if insert_rows:
        cursor.executemany("""
                INSERT IGNORE INTO surveillances (id_prof, id_planning)
    VALUES (%s, %s)

        """, insert_rows)

        conn.commit()

    elapsed = time.time() - start_time
    print("✅ Professor assignment completed")
    print(f"📊 Surveillances created : {len(insert_rows)}")
    print(f"⏱ Execution time       : {elapsed:.2f} seconds")

except Exception as e:
    print("❌ Error occurred")
    print(e)
    import traceback
    traceback.print_exc()
    sys.exit(1)

finally:
    if cursor:
        cursor.close()
    if conn:
        conn.close()

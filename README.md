# 📱 MediMate – Medicine Reminder & Health Tracker  

MediMate is a **Flutter-based mobile application** that helps users manage their daily medicines and monitor health vitals. The app ensures timely reminders, provides a calendar schedule, and maintains a history log for better health management.  

---

## ✨ Features  

- **Add/Edit/Delete Medicines** – Manage medicines with dosage, frequency, and timings.  
- **Daily Reminders** – Local notifications to remind users of scheduled medicines.  
- **Calendar View** – View daily/weekly medicine schedule.  
- **Medicine History Log** – Track taken and missed doses.  
- **Health Tracker** – Log health vitals like BP, sugar, etc., with graphs.  
- **User Profile & Emergency Contact** – Store personal details and quick SOS contact.  

---

## 🛠️ Tech Stack  

- **Framework:** Flutter  
- **Database:** SQLite (with optional Firebase integration)  
- **Notifications:** flutter_local_notifications  
- **Charts & Graphs:** fl_chart / syncfusion_flutter_charts  
- **Calendar:** table_calendar  
- **State Management:** Provider  

---

## 📦 Dependencies  

```yaml
dependencies:
  flutter:
    sdk: flutter
  flutter_local_notifications: ^x.x.x
  sqflite: ^x.x.x
  path_provider: ^x.x.x
  table_calendar: ^x.x.x
  fl_chart: ^x.x.x
  provider: ^x.x.x

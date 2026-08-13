💊 PillMinder — Medicine Reminder App

A production-focused, offline-first medicine reminder application built with Flutter. PillMinder is designed to provide reliable medication scheduling, local notifications, dose tracking, and reminder recovery across app closures and device restarts.

🎯 Objective

Build a reliable, user-friendly, and production-ready Medicine Reminder application using:

Flutter

Hive

Local Notifications

Clean Architecture

Riverpod / Bloc

Android + iOS

Offline-first architecture

The application should reliably handle the complete reminder lifecycle:

Create medicine
      ↓
Close app
      ↓
Reminder appears
      ↓
Take medicine
      ↓
Close app
      ↓
Next reminder appears

It must also recover correctly after a device restart:

Create medicine
      ↓
Restart phone
      ↓
Open app
      ↓
Medicine data remains
      ↓
Future reminders remain correctly scheduled

Platform-appropriate recovery and reminder rescheduling must be implemented.

✨ Core Requirements

Medicine Management

Create medicines

Edit medicines

Delete medicines

Configure dosage and schedules

Configure start and end dates

Support medicines without an end date

Support multiple doses per day

Support a single-day medicine schedule

Reminder Management

Schedule local notifications for future doses

Support multiple reminders per medicine

Prevent duplicate notifications

Handle reminders while the app is closed

Recover/reschedule reminders after device restart

Reschedule reminders when medicine details change

Cancel scheduled reminders when a medicine is deleted

Dose Tracking

Each dose occurrence should support:

Taken

Skipped

Snoozed

Automatically missed

The application should maintain a reliable history of dose occurrences.

🏗️ Clean Architecture

The project should follow clean, maintainable architecture with clear separation of responsibilities.

Recommended structure:

lib/
├── core/
│
├── features/
│   ├── dashboard/
│   ├── medicine/
│   ├── reminder/
│   ├── history/
│   └── settings/
│
├── data/
├── domain/
└── presentation/

Recommended application flow:

UI
 ↓
State Management
 ↓
Use Case
 ↓
Repository
 ↓
Hive / Notification Service

Architecture Principles

UI widgets should remain presentation-focused.

Business logic must not be placed directly inside UI widgets.

Domain logic should be independent of Flutter-specific UI code where practical.

Data access should happen through repositories.

Notification scheduling should be handled by a dedicated notification service.

Local persistence should be abstracted behind repository interfaces.

Features should remain modular and testable.

💾 Offline-First

PillMinder should work without requiring an internet connection.

Local Storage

Use Hive for persistent local data such as:

Medicines

Medicine schedules

Dose occurrences

Dose status

Reminder configuration

Relevant application settings

The app should restore its state from local storage after:

App closure

App relaunch

Device restart

🔔 Notifications

Use local notifications to deliver medicine reminders.

The notification system should support:

Future scheduled reminders

Multiple doses per day

Notification cancellation

Notification rescheduling

Duplicate prevention

App-closed reminders

Device-restart recovery

Reminder Recovery

On application startup, the system should verify the persisted medicine schedules and reconcile them with the currently scheduled notifications.

Conceptually:

App Start
   ↓
Load medicines from Hive
   ↓
Load active schedules
   ↓
Validate future occurrences
   ↓
Detect missing/invalid notifications
   ↓
Reschedule required reminders

Platform-specific behavior and operating-system notification restrictions should be handled appropriately for Android and iOS.

📅 Dose Occurrences

A medicine schedule should generate individual dose occurrences.

For example:

Start Date: 10 Aug
End Date:   16 Aug
Doses/Day:  3

Expected:

7 days × 3 doses = 21 dose occurrences

Therefore:

10 Aug → 16 Aug with 3 doses/day = 21 dose occurrences

Each occurrence should be independently trackable as:

Scheduled
Taken
Skipped
Snoozed
Missed

🧪 Testing Requirements

The application must be tested for the following scenarios:

Medicine Scheduling

Multiple doses per day

Start/end dates

No end date

Same start/end date

Different medicine schedules

Dose Status

Taken

Skipped

Automatically missed

Snooze

Notifications

Local notifications appear correctly

App closed

App reopened

Phone restarted

Future reminders are recovered

Duplicate notifications are prevented

Medicine Updates

Medicine editing

Medicine deletion

Schedule changes

Notification rescheduling after editing

Notification cancellation after deletion

History

Dose history is persisted

Taken doses appear correctly

Skipped doses appear correctly

Missed doses appear correctly

History remains available after app restart

Search and Filters

Medicine search

History search

Relevant filters

Empty search results

🎨 UI / UX

The application should have a modern, clean, and user-friendly design.

Requirements

Responsive Android and iOS layouts

Clean typography

Consistent spacing

Clear primary and secondary actions

Clear dose status indicators

Useful empty states

Loading states where required

Proper error handling

Accessible UI

Light/Dark theme support where practical

Consistent navigation

Clear confirmation for destructive actions

The final application should feel like a real production application rather than a tutorial or college project.

📱 Platform Support

PillMinder targets:

Android

iOS

Platform-specific notification behavior, permissions, scheduling limitations, and restart/recovery mechanisms should be handled according to each operating system.

🧩 Suggested Feature Modules

Dashboard

Provides an overview of the user's medication schedule and upcoming doses.

Possible responsibilities:

Today's medicines

Upcoming doses

Dose status

Quick actions

Empty states

Medicine

Responsible for medicine lifecycle management:

Create
 ↓
View
 ↓
Edit
 ↓
Delete

Reminder

Responsible for:

Schedule generation

Notification scheduling

Snooze

Reminder cancellation

Reminder recovery

Duplicate prevention

History

Responsible for:

Dose occurrence history

Taken doses

Skipped doses

Missed doses

Search

Filters

Settings

Responsible for application-level preferences and notification-related configuration.

🔄 Reminder Lifecycle

The expected lifecycle is:

Create Medicine
      ↓
Generate Dose Occurrences
      ↓
Persist Data in Hive
      ↓
Schedule Local Notifications
      ↓
Notification Triggered
      ↓
User Action
 ┌────┼──────────┐
 ↓    ↓          ↓
Taken Skipped  Snooze
 ↓    ↓          ↓
Update Dose Status
      ↓
Persist History
      ↓
Next Reminder

For an unhandled dose:

Reminder Time Passed
        ↓
Dose Not Completed
        ↓
Mark as Missed
        ↓
Persist History

🛡️ Reliability Requirements

The reminder system should prioritize reliability.

Important considerations:

Persist schedules before relying on them.

Use deterministic identifiers for scheduled notifications.

Prevent duplicate notification scheduling.

Reconcile stored schedules with scheduled platform notifications.

Reschedule future reminders after relevant lifecycle events.

Ensure deleting/editing a medicine does not leave stale notifications.

Handle notification permission states gracefully.

Handle invalid or expired schedules safely.

📦 Recommended Technology Stack

Area

Technology

Framework

Flutter

Language

Dart

Local Database

Hive

Notifications

Local Notifications

State Management

Riverpod / Bloc

Architecture

Clean Architecture

Platforms

Android + iOS

Connectivity

Offline-first

🧱 Development Principles

Keep business logic independent from UI widgets.

Prefer reusable components.

Avoid duplicated scheduling logic.

Keep notification IDs deterministic.

Validate user input before persistence.

Handle edge cases explicitly.

Keep repositories testable.

Use meaningful naming conventions.

Handle errors instead of silently ignoring failures.

Avoid unnecessary network dependencies.

Maintain consistent UI behavior across Android and iOS.

🚀 Production Readiness Checklist

Clean Architecture implemented

Hive persistence implemented

Local notifications implemented

Medicine CRUD completed

Multiple-dose scheduling completed

Start/end date handling completed

No-end-date handling completed

Taken/Skipped/Missed states completed

Snooze implemented

History implemented

Search implemented

Filters implemented

Duplicate notification prevention implemented

App-closed reminder behavior tested

Device-restart recovery tested

Medicine edit/delete rescheduling tested

Android tested

iOS tested

Responsive UI tested

Error states handled

Accessibility reviewed

Light/Dark theme reviewed

🎨 UX Inspiration

Existing medicine reminder applications such as Medisafe and MyTherapy may be studied for UX ideas and general product patterns.

Their designs and source code must not be copied.

PillMinder should have its own visual identity, interaction patterns, and implementation.

📌 Expected Result

The completed PillMinder application should provide a reliable medication reminder experience where:

Medicine Created
      ↓
Data Persisted Locally
      ↓
Reminder Scheduled
      ↓
App Can Be Closed
      ↓
Reminder Still Appears
      ↓
Dose Can Be Taken / Skipped / Snoozed
      ↓
History Is Updated
      ↓
Next Reminder Is Available

And after a device restart:

Device Restart
      ↓
Application Starts
      ↓
Persisted Medicine Data Restored
      ↓
Future Schedule Reconciled
      ↓
Missing Reminders Rescheduled
      ↓
Medication Reminders Continue Reliably

The goal is a production-level, offline-first Flutter medicine reminder application with reliable persistence, notification scheduling, recovery, dose tracking, and a polished user experience.

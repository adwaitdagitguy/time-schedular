# 🔗 Frontend-Backend Integration Guide

## ⚠️ **CURRENT PROBLEMS**

### 1. **Frontend Using Supabase Directly** ❌
Your frontend (`Dashboard.tsx`) is calling Supabase directly instead of your Spring Boot backend:

```typescript
// WRONG - Calling Supabase directly
await supabase.from('meetings').select('*')
await supabase.from('schedules').insert(...)
```

**Problem**: Your backend's weighted algorithm, business logic, and validation are ALL BYPASSED!

---

### 2. **No Role-Based Access Control** ❌
- No check for user role (EXECUTIVE, SECRETARY, ADMIN)
- Everyone sees the same UI
- No role-specific features

---

### 3. **Optimize Schedule Not Using Backend** ❌
The optimization is running IN THE FRONTEND using a simple JavaScript function, not your sophisticated Java backend algorithm!

---

## ✅ **SOLUTION: Proper Integration**

### Architecture Should Be:
```
Frontend (React) → Backend (Spring Boot) → Database (Supabase PostgreSQL)
                    ↑
                    All business logic here!
```

---

## 🔧 **Step-by-Step Fix**

### Step 1: Create API Service Layer (Frontend)

Create `src/lib/api.ts`:

```typescript
const API_BASE_URL = 'http://localhost:8081/api';

export const api = {
  // Meetings
  async getMeetings(userId: string) {
    const response = await fetch(`${API_BASE_URL}/meetings/user/${userId}`);
    return response.json();
  },

  async createMeeting(userId: string, meeting: any) {
    const response = await fetch(`${API_BASE_URL}/meetings/user/${userId}`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(meeting)
    });
    return response.json();
  },

  async markMeetingCompleted(meetingId: string, userId: string) {
    const response = await fetch(`${API_BASE_URL}/meetings/${meetingId}/complete/user/${userId}`, {
      method: 'POST'
    });
    return response.json();
  },

  // Schedule
  async getSchedules(userId: string) {
    const response = await fetch(`${API_BASE_URL}/schedules/user/${userId}`);
    return response.json();
  },

  async optimizeSchedule(userId: string) {
    const response = await fetch(`${API_BASE_URL}/schedules/optimize/user/${userId}`, {
      method: 'POST'
    });
    return response.json();
  },

  // Availability
  async getAvailability(userId: string) {
    const response = await fetch(`${API_BASE_URL}/availability/user/${userId}`);
    return response.json();
  },

  async createAvailability(userId: string, availability: any) {
    const response = await fetch(`${API_BASE_URL}/availability/user/${userId}`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(availability)
    });
    return response.json();
  }
};
```

---

### Step 2: Update Dashboard to Use Backend

**BEFORE** (Wrong - Direct Supabase):
```typescript
// ❌ BAD: Bypassing backend
const { data } = await supabase.from('meetings').select('*');
```

**AFTER** (Correct - Using Backend):
```typescript
// ✅ GOOD: Using backend with all business logic
import { api } from '../lib/api';

const meetings = await api.getMeetings(user.id);
```

---

### Step 3: Fix Optimize Schedule

**BEFORE** (Wrong):
```typescript
// ❌ Running algorithm in frontend
const optimizedSchedule = optimizeSchedule(pendingMeetings, availabilityData);

// Then manually updating database
for (const item of optimizedSchedule) {
  await supabase.from('schedules').insert({...});
}
```

**AFTER** (Correct):
```typescript
// ✅ Backend does EVERYTHING
async function handleOptimizeSchedule() {
  try {
    const result = await api.optimizeSchedule(user.id);
    
    setNotifications(prev => [{
      id: crypto.randomUUID(),
      message: `✨ ${result.scheduledMeetings.length} meetings optimized!`,
      timestamp: new Date().toISOString(),
    }, ...prev]);
    
    await loadData(); // Refresh
  } catch (error) {
    alert(error.message);
  }
}
```

---

### Step 4: Implement Role-Based Access

**Add Role to User Interface**:
```typescript
interface User {
  id: string;
  email: string;
  full_name: string;
  role: 'EXECUTIVE' | 'SECRETARY' | 'ADMIN'; // ADD THIS
}
```

**Role-Based UI Components**:
```typescript
export default function Dashboard() {
  const { user } = useAuth();
  
  return (
    <div>
      {/* Executive Dashboard */}
      {user.role === 'EXECUTIVE' && (
        <div>
          <button onClick={handleOptimizeSchedule}>Optimize My Schedule</button>
          <button onClick={createMeeting}>Create Meeting</button>
        </div>
      )}
      
      {/* Secretary Dashboard */}
      {user.role === 'SECRETARY' && (
        <div>
          <h2>Manage Executives</h2>
          <ExecutiveSelector />
          <button onClick={optimizeForExecutive}>Optimize Executive's Schedule</button>
        </div>
      )}
      
      {/* Admin Dashboard */}
      {user.role === 'ADMIN' && (
        <div>
          <h2>System Administration</h2>
          <UserManagement />
          <SystemStatistics />
        </div>
      )}
    </div>
  );
}
```

---

## 📝 **Complete Updated Dashboard.tsx**

```typescript
import { useState, useEffect } from 'react';
import { useAuth } from '../contexts/AuthContext';
import { api } from '../lib/api'; // NEW: API service
import { Calendar, Clock, Plus, LogOut, Bell, CheckCircle } from 'lucide-react';

export default function Dashboard() {
  const { user, setUser } = useAuth();
  const [meetings, setMeetings] = useState([]);
  const [schedules, setSchedules] = useState([]);
  const [loading, setLoading] = useState(true);

  async function loadData() {
    if (!user) return;
    
    try {
      // ✅ Using backend API
      const [meetingsData, schedulesData] = await Promise.all([
        api.getMeetings(user.id),
        api.getSchedules(user.id)
      ]);
      
      setMeetings(meetingsData);
      setSchedules(schedulesData);
    } catch (error) {
      console.error('Error loading data:', error);
    } finally {
      setLoading(false);
    }
  }

  async function handleOptimizeSchedule() {
    if (!user) return;

    try {
      // ✅ Backend runs the weighted algorithm!
      const result = await api.optimizeSchedule(user.id);
      
      alert(`✨ Success! Scheduled ${result.scheduledMeetings.length} meetings with score ${result.optimizationScore.toFixed(2)}`);
      
      await loadData(); // Refresh data
    } catch (error) {
      alert('Error: ' + error.message);
    }
  }

  async function handleMarkAsCompleted(meetingId: string) {
    if (!user) return;

    try {
      // ✅ Using backend API
      await api.markMeetingCompleted(meetingId, user.id);
      await loadData();
    } catch (error) {
      alert('Error: ' + error.message);
    }
  }

  // Rest of component...
}
```

---

## 🎯 **Backend Endpoints Summary**

| Feature | Method | Endpoint | Status |
|---------|--------|----------|--------|
| Get Meetings | GET | `/api/meetings/user/{userId}` | ✅ Ready |
| Create Meeting | POST | `/api/meetings/user/{userId}` | ✅ Ready |
| Update Meeting | PUT | `/api/meetings/{id}/user/{userId}` | ✅ Ready |
| Delete Meeting | DELETE | `/api/meetings/{id}/user/{userId}` | ✅ Ready |
| **Mark Completed** | POST | `/api/meetings/{id}/complete/user/{userId}` | ✅ Ready |
| **Optimize Schedule** | POST | `/api/schedules/optimize/user/{userId}` | ✅ Ready |
| Get Schedules | GET | `/api/schedules/user/{userId}` | ✅ Ready |
| Get Availability | GET | `/api/availability/user/{userId}` | ✅ Ready |
| Create Availability | POST | `/api/availability/user/{userId}` | ✅ Ready |

---

## 🚨 **Critical Issues to Fix**

### Issue 1: Frontend Scheduler Algorithm
**File**: `src/lib/scheduler.ts`

This file should be **DELETED** or **REMOVED** from usage. The algorithm should ONLY run on the backend!

```typescript
// ❌ DELETE THIS FILE or don't use it
// src/lib/scheduler.ts

export function optimizeSchedule(meetings, availability) {
  // This is bypassing your backend!
}
```

### Issue 2: Direct Supabase Calls

**Find and replace ALL**:
```typescript
// ❌ REMOVE
await supabase.from('meetings')...
await supabase.from('schedules')...
await supabase.from('availability')...

// ✅ REPLACE WITH
await api.getMeetings()...
await api.getSchedules()...
await api.getAvailability()...
```

---

## 🔐 **Role-Based Features**

### Executive Features:
- ✅ Create meetings
- ✅ Optimize their own schedule
- ✅ Mark meetings as done
- ✅ View their statistics

### Secretary Features:
- ✅ Select which executive to manage
- ✅ Create meetings for executives
- ✅ Optimize executive's schedule
- ✅ Manage multiple executives

### Admin Features:
- ✅ View all users
- ✅ Change user roles
- ✅ View system statistics
- ✅ Manage permissions

---

## 📋 **Action Items**

### Immediate (Priority 1):
1. ✅ Update all controllers to UUID (DONE)
2. ⏳ Create `api.ts` service layer
3. ⏳ Update Dashboard to use `api` instead of Supabase
4. ⏳ Remove/disable frontend scheduler algorithm
5. ⏳ Add role field to user context

### Next (Priority 2):
6. ⏳ Create role-based components
7. ⏳ Implement Secretary dashboard
8. ⏳ Implement Admin dashboard
9. ⏳ Add role-based route protection

### Later (Priority 3):
10. ⏳ Add JWT authentication
11. ⏳ Add error handling/retry logic
12. ⏳ Add loading states
13. ⏳ Add success/error toasts

---

## 🎬 **Quick Start to Fix**

### 1. Create API Service (5 mins)
```bash
# Create new file
touch src/lib/api.ts
```

Copy the API service code above into it.

### 2. Update Dashboard (10 mins)
Replace all `supabase.from(...)` calls with `api.(...)` calls.

### 3. Test Backend Connection (2 mins)
```bash
# Make sure backend is running
cd backend
mvn spring-boot:run

# In browser console
fetch('http://localhost:8081/api/meetings/user/YOUR-USER-ID')
  .then(r => r.json())
  .then(console.log)
```

---

## ✅ **Verification Checklist**

After fixing:
- [ ] Frontend calls backend API (not Supabase)
- [ ] Optimize schedule uses backend algorithm
- [ ] Mark as done uses backend endpoint
- [ ] User role is stored and displayed
- [ ] Different UI for different roles
- [ ] Backend is running on port 8080
- [ ] No CORS errors in browser console
- [ ] All CRUD operations work

---

## 🎯 **Expected Flow**

```
User clicks "Optimize Schedule"
    ↓
Frontend: api.optimizeSchedule(userId)
    ↓
Backend: /api/schedules/optimize/user/{userId}
    ↓
Service: scheduleService.optimizeSchedule()
    ↓
Algorithm: WeightedPriorityAlgorithm.optimizeSchedule()
    ↓
    • Calculates scores (40% priority, 40% deadline, 20% duration)
    • Sorts meetings by score
    • Places in available slots
    • Updates database
    ↓
Returns: OptimizedScheduleResult with scheduledMeetings[]
    ↓
Frontend: Display success message + reload data
```

---

## 🚀 **Result After Proper Integration**

✅ Backend algorithm is used (proper weighted scheduling)  
✅ Business logic in one place (maintainable)  
✅ Role-based access control  
✅ Validation and error handling  
✅ Consistent data flow  
✅ Scalable architecture  

**Your sophisticated backend is finally being used properly!** 🎉




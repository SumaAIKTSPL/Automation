#!/bin/bash

# --- Configuration ---
PROJECT_NAME="office-management-system"
SERVER_DIR="server"
CLIENT_DIR="client/src/modules/attendance"

echo "🚀 Starting Setup for Module 3: Attendance & Leave Management..."

# 1. Create Directory Structure
echo "📂 Creating directories..."
mkdir -p "$SERVER_DIR/models"
mkdir -p "$SERVER_DIR/routes"
mkdir -p "$CLIENT_DIR"

# 2. Setup Backend (Node.js)
echo "⚙️ Setting up Backend..."
cd "$SERVER_DIR"

# Initialize package.json if it doesn't exist
if [ ! -f package.json ]; then
  npm init -y > /dev/null
  echo "📦 Installing backend dependencies (express, mongoose, cors, dotenv)..."
  npm install express mongoose cors dotenv
fi

# ---------------------------------------------------------
# GENERATE BACKEND FILES
# ---------------------------------------------------------

# Create Attendance Model
cat <<EOF > models/Attendance.js
const mongoose = require('mongoose');

const attendanceSchema = new mongoose.Schema({
  employeeId: { type: String, required: true },
  date: { type: String, required: true }, // Format: YYYY-MM-DD
  checkIn: { type: Date },
  checkOut: { type: Date },
  location: { type: String, default: 'Office' },
  status: { 
    type: String, 
    enum: ['Present', 'Absent', 'Half-day'], 
    default: 'Present' 
  }
}, { timestamps: true });

module.exports = mongoose.model('Attendance', attendanceSchema);
EOF
echo "✅ Created models/Attendance.js"

# Create Leave Model
cat <<EOF > models/Leave.js
const mongoose = require('mongoose');

const leaveSchema = new mongoose.Schema({
  employeeId: { type: String, required: true },
  type: { type: String, enum: ['Sick', 'Casual', 'Earned'], required: true },
  startDate: { type: Date, required: true },
  endDate: { type: Date, required: true },
  reason: { type: String, required: true },
  status: { 
    type: String, 
    enum: ['Pending', 'Approved', 'Rejected'], 
    default: 'Pending' 
  }
}, { timestamps: true });

module.exports = mongoose.model('Leave', leaveSchema);
EOF
echo "✅ Created models/Leave.js"

# Create Employee Routes
cat <<EOF > routes/employeeRoutes.js
const express = require('express');
const router = express.Router();
const Attendance = require('../models/Attendance');
const Leave = require('../models/Leave');

// --- ATTENDANCE ENDPOINTS ---

// Check Status for Today
router.get('/attendance/status/:id', async (req, res) => {
  try {
    const today = new Date().toISOString().split('T')[0];
    const record = await Attendance.findOne({ employeeId: req.params.id, date: today });
    res.json(record || { status: 'Not Checked In' });
  } catch (err) { res.status(500).json({ error: err.message }); }
});

// Check In
router.post('/attendance/checkin', async (req, res) => {
  try {
    const { employeeId, location } = req.body;
    const today = new Date().toISOString().split('T')[0];
    
    // Check if already checked in
    const existing = await Attendance.findOne({ employeeId, date: today });
    if (existing) return res.status(400).json({ message: 'Already checked in' });

    const newRecord = new Attendance({
      employeeId,
      date: today,
      checkIn: new Date(),
      location: location || 'Office',
      status: 'Present'
    });
    
    await newRecord.save();
    res.json({ message: 'Checked in successfully', record: newRecord });
  } catch (err) { res.status(500).json({ error: err.message }); }
});

// Check Out
router.post('/attendance/checkout', async (req, res) => {
  try {
    const { employeeId } = req.body;
    const today = new Date().toISOString().split('T')[0];
    
    const record = await Attendance.findOneAndUpdate(
      { employeeId, date: today },
      { checkOut: new Date() },
      { new: true }
    );
    
    res.json({ message: 'Checked out successfully', record });
  } catch (err) { res.status(500).json({ error: err.message }); }
});

// --- LEAVE ENDPOINTS ---

// Apply for Leave
router.post('/leave/apply', async (req, res) => {
  try {
    const newLeave = new Leave(req.body);
    await newLeave.save();
    res.json({ message: 'Leave request submitted', leave: newLeave });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Get My Leaves
router.get('/leave/history/:id', async (req, res) => {
  try {
    const leaves = await Leave.find({ employeeId: req.params.id }).sort({ createdAt: -1 });
    res.json(leaves);
  } catch (err) { res.status(500).json({ error: err.message }); }
});

module.exports = router;
EOF
echo "✅ Created routes/employeeRoutes.js"

# Create Main Server Entry Point (if not exists)
if [ ! -f server.js ]; then
cat <<EOF > server.js
const express = require('express');
const mongoose = require('mongoose');
const cors = require('cors');
const employeeRoutes = require('./routes/employeeRoutes');

const app = express();
app.use(cors());
app.use(express.json());

// Database Connection
mongoose.connect('mongodb://localhost:27017/office_management_db', {
  useNewUrlParser: true,
  useUnifiedTopology: true
}).then(() => console.log('MongoDB Connected'))
  .catch(err => console.log(err));

// Routes
app.use('/api', employeeRoutes);

const PORT = 5000;
app.listen(PORT, () => console.log(\`Server running on port \${PORT}\`));
EOF
echo "✅ Created server/server.js"
else
  echo "⚠️ server.js already exists. Please manually add: app.use('/api', require('./routes/employeeRoutes'));"
fi

# ---------------------------------------------------------
# GENERATE FRONTEND FILES
# ---------------------------------------------------------
cd .. # Go back to root
echo "🎨 Setting up Frontend Component..."

# Create the React Component
cat <<EOF > $CLIENT_DIR/AttendanceDashboard.jsx
import React, { useState, useEffect } from 'react';
import axios from 'axios';

const AttendanceDashboard = () => {
  // Hardcoded User ID for testing (In real app, get from Context/Auth)
  const USER_ID = "EMP123"; 
  
  const [status, setStatus] = useState(null);
  const [leaves, setLeaves] = useState([]);
  const [showLeaveModal, setShowLeaveModal] = useState(false);

  // Load initial data
  useEffect(() => {
    fetchStatus();
    fetchLeaves();
  }, []);

  const fetchStatus = async () => {
    try {
      const res = await axios.get(\`http://localhost:5000/api/attendance/status/\${USER_ID}\`);
      setStatus(res.data);
    } catch (err) { console.error(err); }
  };

  const fetchLeaves = async () => {
    try {
      const res = await axios.get(\`http://localhost:5000/api/leave/history/\${USER_ID}\`);
      setLeaves(res.data);
    } catch (err) { console.error(err); }
  };

  const handleCheckIn = async () => {
    if ("geolocation" in navigator) {
      navigator.geolocation.getCurrentPosition(async (position) => {
        const { latitude, longitude } = position.coords;
        await axios.post('http://localhost:5000/api/attendance/checkin', {
          employeeId: USER_ID,
          location: \`\${latitude}, \${longitude}\`
        });
        fetchStatus();
      });
    } else {
      alert("GPS not supported");
    }
  };

  const handleCheckOut = async () => {
    await axios.post('http://localhost:5000/api/attendance/checkout', { employeeId: USER_ID });
    fetchStatus();
  };

  return (
    <div className="p-6 bg-gray-50 min-h-screen">
      <h1 className="text-3xl font-bold text-gray-800 mb-6">Attendance & Leave</h1>

      {/* --- TOP ROW: Check-In Widget --- */}
      <div className="grid grid-cols-1 md:grid-cols-2 gap-6 mb-8">
        <div className="bg-white p-6 rounded-xl shadow-md border-l-4 border-blue-500">
          <h2 className="text-xl font-semibold mb-2">Today's Status</h2>
          <p className="text-gray-500 text-sm mb-4">{new Date().toDateString()}</p>
          
          <div className="flex items-center space-x-4">
            {!status?.checkIn ? (
              <button 
                onClick={handleCheckIn}
                className="bg-green-600 hover:bg-green-700 text-white px-6 py-3 rounded-lg font-bold transition shadow-lg w-full">
                📍 Check In
              </button>
            ) : !status?.checkOut ? (
              <button 
                onClick={handleCheckOut}
                className="bg-red-500 hover:bg-red-600 text-white px-6 py-3 rounded-lg font-bold transition shadow-lg w-full">
                ⏱ Check Out
              </button>
            ) : (
              <div className="text-center w-full bg-green-100 text-green-800 p-3 rounded-lg font-bold">
                ✅ Day Completed
              </div>
            )}
          </div>
          {status?.checkIn && (
             <div className="mt-4 text-sm text-gray-600">
               In: {new Date(status.checkIn).toLocaleTimeString()}
               {status.checkOut && \` | Out: \${new Date(status.checkOut).toLocaleTimeString()}\`}
             </div>
          )}
        </div>

        {/* --- Quick Actions --- */}
        <div className="bg-white p-6 rounded-xl shadow-md">
           <h2 className="text-xl font-semibold mb-4">Quick Actions</h2>
           <button 
             onClick={() => setShowLeaveModal(true)}
             className="w-full bg-purple-600 text-white py-3 rounded-lg font-semibold hover:bg-purple-700 mb-3 transition">
             ✈️ Apply for Leave
           </button>
           <button className="w-full border border-gray-300 text-gray-700 py-3 rounded-lg font-semibold hover:bg-gray-50 transition">
             📅 View Holiday Calendar
           </button>
        </div>
      </div>

      {/* --- Leave History Table --- */}
      <div className="bg-white rounded-xl shadow-md overflow-hidden">
        <div className="px-6 py-4 border-b border-gray-200">
          <h3 className="font-bold text-lg">Leave History</h3>
        </div>
        <table className="w-full text-left border-collapse">
          <thead>
            <tr className="bg-gray-100 text-gray-600 text-sm uppercase">
              <th className="px-6 py-3">Type</th>
              <th className="px-6 py-3">Dates</th>
              <th className="px-6 py-3">Reason</th>
              <th className="px-6 py-3">Status</th>
            </tr>
          </thead>
          <tbody className="divide-y divide-gray-200">
            {leaves.map((leave) => (
              <tr key={leave._id} className="hover:bg-gray-50">
                <td className="px-6 py-4 font-medium">{leave.type}</td>
                <td className="px-6 py-4 text-sm">
                   {new Date(leave.startDate).toLocaleDateString()} - {new Date(leave.endDate).toLocaleDateString()}
                </td>
                <td className="px-6 py-4 text-gray-500 text-sm truncate max-w-xs">{leave.reason}</td>
                <td className="px-6 py-4">
                  <span className={\`px-3 py-1 rounded-full text-xs font-bold 
                    \${leave.status === 'Approved' ? 'bg-green-100 text-green-800' : 
                      leave.status === 'Rejected' ? 'bg-red-100 text-red-800' : 
                      'bg-yellow-100 text-yellow-800'}\`}>
                    {leave.status}
                  </span>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>

      {/* --- Leave Application Modal --- */}
      {showLeaveModal && (
        <LeaveModal 
          close={() => setShowLeaveModal(false)} 
          userId={USER_ID} 
          refresh={fetchLeaves} 
        />
      )}
    </div>
  );
};

// Simple Modal Component
const LeaveModal = ({ close, userId, refresh }) => {
  const [formData, setFormData] = useState({
    type: 'Sick', startDate: '', endDate: '', reason: ''
  });

  const handleSubmit = async (e) => {
    e.preventDefault();
    await axios.post('http://localhost:5000/api/leave/apply', { ...formData, employeeId: userId });
    refresh();
    close();
  };

  return (
    <div className="fixed inset-0 bg-black bg-opacity-50 flex justify-center items-center z-50">
      <div className="bg-white rounded-lg p-6 w-96 shadow-2xl">
        <h2 className="text-xl font-bold mb-4">Apply for Leave</h2>
        <form onSubmit={handleSubmit}>
          <div className="mb-3">
            <label className="block text-sm font-medium mb-1">Leave Type</label>
            <select className="w-full border rounded p-2" 
              onChange={e => setFormData({...formData, type: e.target.value})}>
              <option>Sick</option>
              <option>Casual</option>
              <option>Earned</option>
            </select>
          </div>
          <div className="mb-3 grid grid-cols-2 gap-2">
            <div>
              <label className="block text-sm font-medium mb-1">From</label>
              <input type="date" className="w-full border rounded p-2" required
                onChange={e => setFormData({...formData, startDate: e.target.value})} />
            </div>
            <div>
              <label className="block text-sm font-medium mb-1">To</label>
              <input type="date" className="w-full border rounded p-2" required
                onChange={e => setFormData({...formData, endDate: e.target.value})} />
            </div>
          </div>
          <div className="mb-4">
            <label className="block text-sm font-medium mb-1">Reason</label>
            <textarea className="w-full border rounded p-2 h-20" required
              onChange={e => setFormData({...formData, reason: e.target.value})}></textarea>
          </div>
          <div className="flex justify-end space-x-2">
            <button type="button" onClick={close} className="px-4 py-2 text-gray-600">Cancel</button>
            <button type="submit" className="px-4 py-2 bg-blue-600 text-white rounded hover:bg-blue-700">Submit</button>
          </div>
        </form>
      </div>
    </div>
  );
};

export default AttendanceDashboard;
EOF
echo "✅ Created $CLIENT_DIR/AttendanceDashboard.jsx"

echo "--------------------------------------------------------"
echo "🎉 Module 3 (Attendance & Leave) Setup Complete!"
echo "--------------------------------------------------------"
echo "👉 To run the Backend:"
echo "   cd server && node server.js"
echo ""
echo "👉 To use the Frontend:"
echo "   1. Ensure you have a React project setup."
echo "   2. Import 'AttendanceDashboard' in your App.js"
echo "   3. Make sure you install axios: 'npm install axios'"
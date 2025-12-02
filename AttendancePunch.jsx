import React, { useState, useEffect } from 'react';

const AttendancePunch = () => {
  const [isCheckedIn, setIsCheckedIn] = useState(false);
  const [loading, setLoading] = useState(false);
  const [statusMsg, setStatusMsg] = useState('');
  const [locationData, setLocationData] = useState(null);

  // 1. Define Office Coordinates (Example: Tech Park Center)
  const OFFICE_LAT = 12.9716; 
  const OFFICE_LNG = 77.5946;
  const ALLOWED_RADIUS_METERS = 100;

  // 2. Helper: Calculate distance between two points (Haversine Formula)
  const getDistanceFromLatLonInMeters = (lat1, lon1, lat2, lon2) => {
    const R = 6371e3; // Radius of earth in meters
    const dLat = (lat2 - lat1) * (Math.PI / 180);
    const dLon = (lon2 - lon1) * (Math.PI / 180);
    const a = 
      Math.sin(dLat / 2) * Math.sin(dLat / 2) +
      Math.cos(lat1 * (Math.PI / 180)) * Math.cos(lat2 * (Math.PI / 180)) * Math.sin(dLon / 2) * Math.sin(dLon / 2); 
    const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a)); 
    return R * c; // Distance in meters
  };

  const handlePunch = () => {
    setLoading(true);
    setStatusMsg("Acquiring GPS location...");

    // 3. Browser Geolocation API
    if (!navigator.geolocation) {
      setStatusMsg("Geolocation is not supported by your browser");
      setLoading(false);
      return;
    }

    navigator.geolocation.getCurrentPosition(
      (position) => {
        const { latitude, longitude } = position.coords;
        const distance = getDistanceFromLatLonInMeters(latitude, longitude, OFFICE_LAT, OFFICE_LNG);

        // 4. Validate Location (Geofencing)
        // Note: For testing, you might want to comment out the 'distance > radius' check
        if (distance > ALLOWED_RADIUS_METERS) {
            setStatusMsg(`❌ Failed: You are ${Math.round(distance)}m away from office. Move closer.`);
            setLoading(false);
            return;
        }

        // 5. Success Logic
        const timeNow = new Date().toLocaleTimeString();
        setLocationData({ lat: latitude, lng: longitude });
        setIsCheckedIn(!isCheckedIn); // Toggle State
        setStatusMsg(isCheckedIn ? `Checked Out at ${timeNow}` : `✅ Checked In at ${timeNow}`);
        setLoading(false);
        
        // TODO: Call API here to save data to database
        console.log("API Payload:", { 
            userId: "USER_123", // From Rahul's Auth Module
            type: isCheckedIn ? "OUT" : "IN", 
            lat: latitude, 
            lng: longitude, 
            timestamp: new Date() 
        });
      },
      (error) => {
        setStatusMsg(`Error: ${error.message}`);
        setLoading(false);
      },
      { enableHighAccuracy: true } // Request best possible GPS accuracy
    );
  };

  return (
    <div style={{ border: '1px solid #ccc', padding: '20px', borderRadius: '8px', maxWidth: '400px' }}>
      <h3>Attendance Panel</h3>
      
      {/* Visual Timer or Status */}
      <div style={{ marginBottom: '15px', fontWeight: 'bold' }}>
        Status: <span style={{ color: isCheckedIn ? 'green' : 'red' }}>
            {isCheckedIn ? 'Working' : 'Not Checked In'}
        </span>
      </div>

      {/* The Big Button */}
      <button 
        onClick={handlePunch} 
        disabled={loading}
        style={{
            padding: '15px 30px',
            fontSize: '16px',
            backgroundColor: isCheckedIn ? '#ff4d4f' : '#1890ff',
            color: 'white',
            border: 'none',
            borderRadius: '5px',
            cursor: 'pointer'
        }}
      >
        {loading ? 'Locating...' : (isCheckedIn ? 'Punch OUT' : 'Punch IN')}
      </button>

      {/* Feedback Message */}
      {statusMsg && (
        <p style={{ marginTop: '15px', color: '#555', fontSize: '14px' }}>
          {statusMsg}
        </p>
      )}

      {/* Debug Info (Optional) */}
      {locationData && (
        <small style={{ display: 'block', marginTop: '10px', color: '#999' }}>
          Lat: {locationData.lat.toFixed(4)}, Lng: {locationData.lng.toFixed(4)}
        </small>
      )}
    </div>
  );
};

export default AttendancePunch;
import React, { useState } from 'react';
import { LogIn, UserPlus } from 'lucide-react'; // Using lucide icons

// Main component, must be named 'App' and exported as default for single-file React environment
const App = () => {
  const [isLogin, setIsLogin] = useState(true);
  const [formData, setFormData] = useState({
    email: '',
    password: '',
  });
  const [loading, setLoading] = useState(false);
  const [message, setMessage] = useState('');

  // Handle input changes
  const handleChange = (e) => {
    setFormData({ ...formData, [e.target.name]: e.target.value });
  };

  // Simulate authentication process
  const handleSubmit = async (e) => {
    e.preventDefault();
    setLoading(true);
    setMessage('');

    // --- Simulated Auth Logic ---
    const action = isLogin ? 'Login' : 'Register';
    
    // Simulate API call delay
    await new Promise(resolve => setTimeout(resolve, 1500));

    if (formData.email.includes('@') && formData.password.length >= 6) {
      setMessage(`${action} successful! Email: ${formData.email}`);
      // Clear form after success
      setFormData({ email: '', password: '' });
    } else {
      setMessage(`Error: Invalid credentials for ${action.toLowerCase()}. Password must be 6+ chars.`);
    }

    setLoading(false);
  };

  const toggleMode = () => {
    setIsLogin(prev => !prev);
    setMessage('');
    setFormData({ email: '', password: '' });
  };

  const title = isLogin ? 'Sign In to Your Account' : 'Create a New Account';
  const buttonText = isLogin ? 'Login' : 'Register';

  return (
    <div className="min-h-screen bg-gray-100 flex items-center justify-center p-4 sm:p-6 font-sans">
      <div className="w-full max-w-md bg-white shadow-2xl rounded-xl p-8 space-y-6">
        
        {/* Header */}
        <div className="text-center">
          <h1 className="text-3xl font-extrabold text-indigo-700 mb-2">{title}</h1>
          <p className="text-sm text-gray-500">
            {isLogin ? "Welcome back! Enter your details." : "Join us now and start exploring."}
          </p>
        </div>

        {/* Form */}
        <form onSubmit={handleSubmit} className="space-y-4">
          
          {/* Email Input */}
          <div>
            <label htmlFor="email" className="block text-sm font-medium text-gray-700 mb-1">Email Address</label>
            <input
              id="email"
              name="email"
              type="email"
              required
              value={formData.email}
              onChange={handleChange}
              placeholder="you@example.com"
              className="w-full p-3 border border-gray-300 rounded-lg focus:ring-indigo-500 focus:border-indigo-500 transition duration-150 ease-in-out"
            />
          </div>

          {/* Password Input */}
          <div>
            <label htmlFor="password" className="block text-sm font-medium text-gray-700 mb-1">Password</label>
            <input
              id="password"
              name="password"
              type="password"
              required
              value={formData.password}
              onChange={handleChange}
              placeholder="••••••••"
              minLength={6}
              className="w-full p-3 border border-gray-300 rounded-lg focus:ring-indigo-500 focus:border-indigo-500 transition duration-150 ease-in-out"
            />
          </div>

          {/* Submission Button */}
          <button
            type="submit"
            disabled={loading}
            className="w-full flex justify-center items-center py-3 px-4 border border-transparent rounded-lg shadow-md text-sm font-medium text-white bg-indigo-600 hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500 transition duration-150 ease-in-out disabled:opacity-50"
          >
            {loading ? (
              <svg className="animate-spin h-5 w-5 text-white" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24">
                <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4"></circle>
                <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
              </svg>
            ) : (
              <>
                {isLogin ? <LogIn className="w-5 h-5 mr-2" /> : <UserPlus className="w-5 h-5 mr-2" />}
                {buttonText}
              </>
            )}
          </button>
        </form>

        {/* Message Box */}
        {message && (
          <div className={`p-3 text-center rounded-lg text-sm ${message.startsWith('Error') ? 'bg-red-100 text-red-700' : 'bg-green-100 text-green-700'}`}>
            {message}
          </div>
        )}

        {/* Toggle Mode */}
        <div className="text-center mt-4">
          <button
            onClick={toggleMode}
            className="text-sm text-indigo-600 hover:text-indigo-800 font-medium transition duration-150 ease-in-out"
          >
            {isLogin ? "Don't have an account? Register" : "Already have an account? Login"}
          </button>
        </div>
      </div>
    </div>
  );
};

export default App;
import React, { useState, useEffect } from 'react';
import { Link, useNavigate, useLocation } from 'react-router-dom';
import { Droplets, AlertCircle, Loader2 } from 'lucide-react';
import { Button } from '../../components/ui/Button';
import { supabase } from '../../lib/supabase';
import { useAuth } from '../../contexts/AuthContext';

export const LoginPage: React.FC = () => {
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  
  const navigate = useNavigate();
  const location = useLocation();
  const { user, role } = useAuth();

  // Redirect if already logged in
  useEffect(() => {
    if (user && role) {
      const from = (location.state as any)?.from?.pathname || `/${role}`;
      navigate(from, { replace: true });
    }
  }, [user, role, navigate, location]);

  const handleEmailLogin = async (e: React.FormEvent) => {
    e.preventDefault();
    setLoading(true);
    setError(null);
    const { error } = await supabase.auth.signInWithPassword({ email, password });
    if (error) setError(error.message);
    setLoading(false);
  };

  const handleGoogleLogin = async () => {
    setError(null);
    const { error } = await supabase.auth.signInWithOAuth({ provider: 'google' });
    if (error) setError(error.message);
  };

  return (
    <div className="min-h-screen bg-brand-50 flex flex-col justify-center py-12 px-6 lg:px-8">
      {/* ... (Header same as Phase 2) ... */}
      <div className="sm:mx-auto sm:w-full sm:max-w-md mb-6 flex justify-center items-center gap-2">
         <Droplets className="w-10 h-10 text-brand-500" />
         <span className="text-3xl font-extrabold text-brand-900 tracking-tight">LabaFlow</span>
      </div>

      <div className="sm:mx-auto sm:w-full sm:max-w-md">
        <div className="bg-white py-8 px-6 shadow-soft rounded-3xl sm:px-10">
          
          {error && (
            <div className="mb-4 p-3 bg-red-50 text-red-600 rounded-xl flex items-center gap-2 text-sm font-semibold">
              <AlertCircle className="w-5 h-5" /> {error}
            </div>
          )}

          <form className="space-y-6" onSubmit={handleEmailLogin}>
            <div>
              <label className="block text-sm font-bold text-slate-700">Email address</label>
              <input type="email" required value={email} onChange={(e) => setEmail(e.target.value)}
                className="mt-2 block w-full px-4 py-3 border border-slate-200 rounded-xl focus:ring-brand-500 focus:border-brand-500 bg-slate-50" />
            </div>
            <div>
              <label className="block text-sm font-bold text-slate-700">Password</label>
              <input type="password" required value={password} onChange={(e) => setPassword(e.target.value)}
                className="mt-2 block w-full px-4 py-3 border border-slate-200 rounded-xl focus:ring-brand-500 focus:border-brand-500 bg-slate-50" />
            </div>
            <Button type="submit" variant="primary" fullWidth disabled={loading}>
              {loading ? <Loader2 className="w-5 h-5 animate-spin" /> : 'Sign In'}
            </Button>
          </form>

          <div className="mt-6">
            <div className="relative flex justify-center text-sm border-t border-slate-200 pt-6">
              <span className="absolute -top-3 px-2 bg-white text-slate-500 font-semibold">Or continue with</span>
            </div>
            <Button variant="outline" fullWidth onClick={handleGoogleLogin} className="flex gap-2 justify-center mt-2">
              Google
            </Button>
          </div>
        </div>
      </div>
    </div>
  );
};
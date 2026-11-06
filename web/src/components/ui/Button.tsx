import React from 'react';

interface ButtonProps extends React.ButtonHTMLAttributes<HTMLButtonElement> {
  variant?: 'primary' | 'secondary' | 'outline' | 'ghost';
  fullWidth?: boolean;
}

export const Button: React.FC<ButtonProps> = ({ 
  children, variant = 'primary', fullWidth, className = '', ...props 
}) => {
  const baseStyle = "inline-flex items-center justify-center px-6 py-3 font-bold rounded-full transition-all duration-200 focus:outline-none focus:ring-2 focus:ring-offset-2";
  
  const variants = {
    primary: "bg-brand-500 text-white hover:bg-brand-600 shadow-lg shadow-brand-500/30 focus:ring-brand-500",
    secondary: "bg-brand-100 text-brand-900 hover:bg-brand-200 focus:ring-brand-100",
    outline: "border-2 border-brand-500 text-brand-500 hover:bg-brand-50 focus:ring-brand-500",
    ghost: "text-slate-600 hover:text-brand-500 hover:bg-brand-50 focus:ring-brand-500"
  };

  return (
    <button 
      className={`${baseStyle} ${variants[variant]} ${fullWidth ? 'w-full' : ''} ${className}`}
      {...props}
    >
      {children}
    </button>
  );
};
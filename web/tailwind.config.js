/** @type {import('tailwindcss').Config} */
export default {
  content: [
    "./index.html",
    "./src/**/*.{js,ts,jsx,tsx}",
  ],
  theme: {
    extend: {
      colors: {
        brand: {
          50: '#f0f9ff',  // Soft background
          100: '#e0f2fe',
          400: '#38bdf8',
          500: '#0ea5e9', // Primary CTA
          600: '#0284c7', // Hover state
          900: '#0c4a6e', // Deep accents
        },
        slate: {
          600: '#475569', // Body text
          900: '#0f172a', // Headings
        }
      },
      fontFamily: {
        sans: ['Nunito', 'sans-serif'], // Soft, rounded typography matching the reference
      },
      borderRadius: {
        '2xl': '1rem',
        '3xl': '1.5rem',
        '4xl': '2rem',
      },
      boxShadow: {
        'soft': '0 10px 40px -10px rgba(14, 165, 233, 0.15)',
      }
    },
  },
  plugins: [],
}
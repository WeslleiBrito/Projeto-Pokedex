import { defineConfig } from 'vitest/config';

export default defineConfig({
  base: process.env.NODE_ENV === 'production' ? '/Projeto-Pokedex/' : '/',
  server: {
    host: "0.0.0.0",
    port: 5173
  },
  test: {
    globals: true,
    environment: 'jsdom',
    setupFiles: './tests/setup.ts',
    exclude: ['node_modules', 'dist', '.next', 'out'],
    include: ['tests/**/*.{test,spec}.{js,jsx,ts,tsx}'],
    coverage: {
      provider: 'v8',
      reporter: ['text', 'json', 'html'],
      include: ['src/**/*.{js,jsx,ts,tsx}'],
      exclude: [
        'src/**/*.d.ts',
        'src/**/*.stories.{js,jsx,ts,tsx}',
        'src/**/*.test.{js,jsx,ts,tsx}'
      ], 
      thresholds: {
        lines: 80,
        branches: 80,
        functions: 80,
        statements: 80,
      }
    },

  },
  resolve: {
    alias: {
      '@': '/src'
    }
  }
});
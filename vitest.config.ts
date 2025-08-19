import { defineConfig } from 'vitest/config';

export default defineConfig(
    {
        test: {
            dir: './tests',
            globals: true,
            environment: 'jsdom',
            include: ['tests/**/*.test.{ts,tsx}'],
            coverage: {
                provider: 'v8',
                reporter: [
                    'text',
                    'lcov',
                    'html'
                ],
                thresholds: {
                    lines: 80,
                    branches: 80,
                    functions: 80,
                    statements: 80
                }
            }
        }
    }
);
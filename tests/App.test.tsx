import React from 'react';
import { render, screen, fireEvent } from '@testing-library/react';
import { describe, it, expect } from 'vitest';
import App from '../src/App';

describe('App Component', () => {
  it('deve renderizar o título principal', () => {
    render(<App />);
    expect(screen.getByText('Vite + React')).toBeInTheDocument();
  });

  it('deve renderizar os logos do Vite e React', () => {
    render(<App />);
    
    const viteLogo = screen.getByAltText('Vite logo');
    const reactLogo = screen.getByAltText('React logo');
    
    expect(viteLogo).toBeInTheDocument();
    expect(reactLogo).toBeInTheDocument();
    expect(viteLogo).toHaveAttribute('src', '/vite.svg');
    expect(reactLogo).toHaveAttribute('src', '/src/assets/react.svg');
  });

  it('deve renderizar o botão de contador com valor inicial 0', () => {
    render(<App />);
    expect(screen.getByText('count is 0')).toBeInTheDocument();
  });

  it('deve incrementar o contador quando o botão for clicado', () => {
    render(<App />);
    const button = screen.getByText('count is 0');
    
    fireEvent.click(button);
    expect(screen.getByText('count is 1')).toBeInTheDocument();
    
    fireEvent.click(button);
    expect(screen.getByText('count is 2')).toBeInTheDocument();
  });

  it('deve renderizar o texto de instrução', () => {
    render(<App />);
    
    // ✅ SOLUÇÃO DEFINITIVA: Encontra o parágrafo pelo contexto
    const cardDiv = screen.getByText('count is 0').closest('.card');
    const paragraph = cardDiv?.querySelector('p');
    
    expect(paragraph).toBeInTheDocument();
    expect(paragraph).toHaveTextContent('Edit src/App.tsx and save to test HMR');
  });

  it('deve renderizar o link de documentação', () => {
    render(<App />);
    expect(screen.getByText('Click on the Vite and React logos to learn more')).toBeInTheDocument();
  });

  it('deve ter links com target _blank', () => {
    render(<App />);
    
    const viteLink = screen.getByAltText('Vite logo').closest('a');
    const reactLink = screen.getByAltText('React logo').closest('a');
    
    expect(viteLink).toHaveAttribute('target', '_blank');
    expect(reactLink).toHaveAttribute('target', '_blank');
    expect(viteLink).toHaveAttribute('href', 'https://vite.dev');
    expect(reactLink).toHaveAttribute('href', 'https://react.dev');
  });
});
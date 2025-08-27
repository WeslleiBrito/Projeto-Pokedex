import React from 'react';
import { render, screen, fireEvent } from '@testing-library/react';
import '@testing-library/jest-dom';
import { describe, it, expect } from 'vitest';
import App from '../src/App';

describe('App Component - Pokédex', () => {
  it('deve renderizar o logo da Pokédex', () => {
    render(<App />);
    const logo = screen.getByAltText('Pokédex Logo');
    expect(logo).toBeInTheDocument();
    expect(logo).toHaveAttribute('src', '/img/logo.png');
  });

  it('deve renderizar a imagem de fundo da Pokédex', () => {
    render(<App />);
    const bg = screen.getByAltText('Pokédex background');
    expect(bg).toBeInTheDocument();
    expect(bg).toHaveAttribute('src', '/img/pokedex-bg.png');
  });

  it('deve exibir o estado inicial de carregamento', () => {
    render(<App />);
    expect(screen.getByText('Loading...')).toBeInTheDocument();
  });

  it('deve renderizar a caixa de busca', () => {
    render(<App />);
    const input = screen.getByPlaceholderText('Nome ou número do pokémon');
    expect(input).toBeInTheDocument();
  });

  it('deve renderizar os botões de navegação', () => {
    render(<App />);
    expect(screen.getByText('⬅ Anterior')).toBeInTheDocument();
    expect(screen.getByText('Próximo ➡')).toBeInTheDocument();
    expect(screen.getByText('Aleatório')).toBeInTheDocument();
  });

  it('deve permitir buscar um Pokémon digitando no input', () => {
    render(<App />);
    const input = screen.getByPlaceholderText('Nome ou número do pokémon') as HTMLInputElement;
    const form = input.closest('form');
    expect(form).toBeInTheDocument();

    fireEvent.change(input, { target: { value: 'pikachu' } });
    expect(input.value).toBe('pikachu');
  });
});

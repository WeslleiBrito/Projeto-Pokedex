import React from "react";
import { render, screen, fireEvent, waitFor } from "@testing-library/react";
import "@testing-library/jest-dom";
import { describe, it, expect, vi, beforeEach } from "vitest";
import App from "../src/App";

describe("App Component - Pokédex", () => {
  beforeEach(() => {
    vi.restoreAllMocks();
  });

  function mockFetchSuccess(pokemon: unknown, species: unknown) {
    global.fetch = vi.fn()
      // primeira chamada → /pokemon/:id
      .mockResolvedValueOnce({
        ok: true,
        json: async () => pokemon,
      } as Response)
      // segunda chamada → species.url
      .mockResolvedValueOnce({
        ok: true,
        json: async () => species,
      } as Response);
  }

  function mockFetchError() {
    global.fetch = vi.fn().mockResolvedValue({
      ok: false,
    } as Response);
  }

  it("deve renderizar o logo da Pokédex", async () => {
    mockFetchSuccess(
      { id: 1, name: "bulbasaur", sprites: { front_default: "" }, types: [], height: 7, weight: 69, species: { url: "" } },
      { flavor_text_entries: [] }
    );

    render(<App />);
    expect(screen.getByAltText("Pokédex Logo")).toBeInTheDocument();
  });

  it("deve exibir o estado inicial de carregamento", () => {
    mockFetchError(); // força erro para não travar
    render(<App />);
    expect(screen.getByText("Loading...")).toBeInTheDocument();
  });

  it("deve carregar e exibir um Pokémon com dados completos", async () => {
  mockFetchSuccess(
    {
      id: 25,
      name: "pikachu",
      sprites: {
        front_default: "/img/pikachu.png",
        versions: {
          "generation-v": {
            "black-white": { animated: { front_default: null } },
          },
        },
      },
      types: [{ type: { name: "electric" } }],
      height: 4,
      weight: 60,
      species: { url: "https://pokeapi.co/api/v2/pokemon-species/25" },
    },
    {
      flavor_text_entries: [
        { flavor_text: "Um rato elétrico. Com ataques fortes.", language: { name: "pt-br" } },
      ],
    }
  );

  render(<App />);

  // Use o 'waitFor' para todas as asserções que dependem da API.
  await waitFor(() => {
    // Verifique o texto do nome do Pokémon primeiro
    expect(screen.getByText(/pikachu/i)).toBeInTheDocument();

    // Verifique se os outros elementos estão presentes
    expect(screen.getByText("#25")).toBeInTheDocument();
    expect(screen.getByText("Type: electric")).toBeInTheDocument();
    expect(screen.getByText("Height: 0.4 m | Weight: 6 kg")).toBeInTheDocument();

    const descriptionText = "Um rato elétrico. Com ataques fortes.";
    expect(
      screen.getByText((content, element) => {
        const hasText = (text: string) => content.includes(text);
        const elementHasText = hasText(descriptionText);
        const elementIsParagraph = element?.tagName.toLowerCase() === "p";
        return Boolean(elementIsParagraph && elementHasText);
      })
    ).toBeInTheDocument();

  });
});

  it("deve mostrar 'Pokémon não encontrado!' quando a API retorna erro", async () => {
    mockFetchError();
    render(<App />);

    await waitFor(() => {
      expect(screen.getByText("Pokémon não encontrado!")).toBeInTheDocument();
    });
  });

  it("deve permitir buscar um Pokémon digitando no input e limpá-lo após submit", async () => {
    // mock inicial
    mockFetchSuccess(
      { id: 1, name: "bulbasaur", sprites: { front_default: "" }, types: [], height: 7, weight: 69, species: { url: "" } },
      { flavor_text_entries: [] }
    );

    render(<App />);
    await waitFor(() => {
      expect(screen.getByText(/bulbasaur/i)).toBeInTheDocument();
    });

    // mock para busca pelo input
    mockFetchSuccess(
      { id: 25, name: "pikachu", sprites: { front_default: "" }, types: [], height: 4, weight: 60, species: { url: "" } },
      { flavor_text_entries: [] }
    );

    const input = screen.getByPlaceholderText(/Nome ou número do pokémon/i) as HTMLInputElement;
    fireEvent.change(input, { target: { value: "pikachu" } });
    fireEvent.submit(input.closest("form")!);

    await waitFor(() => {
      expect(screen.getByText(/pikachu/i)).toBeInTheDocument();
    });

    expect(input.value).toBe(""); // input limpou
  });

  it("deve navegar para o próximo Pokémon ao clicar em 'Próximo ➡'", async () => {
    // inicial bulbasaur
    mockFetchSuccess(
      { id: 1, name: "bulbasaur", sprites: { front_default: "" }, types: [], height: 7, weight: 69, species: { url: "" } },
      { flavor_text_entries: [] }
    );

    render(<App />);
    await waitFor(() => {
      expect(screen.getByText(/bulbasaur/i)).toBeInTheDocument();
    });

    // próximo ivysaur
    mockFetchSuccess(
      { id: 2, name: "ivysaur", sprites: { front_default: "" }, types: [], height: 10, weight: 130, species: { url: "" } },
      { flavor_text_entries: [] }
    );

    fireEvent.click(screen.getByText("Próximo ➡"));

    await waitFor(() => {
      expect(screen.getByText(/ivysaur/i)).toBeInTheDocument();
    });
  });

  it("deve navegar para o Pokémon anterior ao clicar em '⬅ Anterior'", async () => {
    // inicial ivysaur
    mockFetchSuccess(
      { id: 2, name: "ivysaur", sprites: { front_default: "" }, types: [], height: 10, weight: 130, species: { url: "" } },
      { flavor_text_entries: [] }
    );

    render(<App />);
    await waitFor(() => {
      expect(screen.getByText(/ivysaur/i)).toBeInTheDocument();
    });

    // anterior bulbasaur
    mockFetchSuccess(
      { id: 1, name: "bulbasaur", sprites: { front_default: "" }, types: [], height: 7, weight: 69, species: { url: "" } },
      { flavor_text_entries: [] }
    );

    fireEvent.click(screen.getByText("⬅ Anterior"));

    await waitFor(() => {
      expect(screen.getByText(/bulbasaur/i)).toBeInTheDocument();
    });
  });

  it("deve carregar um Pokémon aleatório ao clicar em 'Aleatório'", async () => {
    vi.spyOn(Math, "random").mockReturnValue(0); // força randomId = 1

    // mock inicial
    mockFetchSuccess(
      { id: 1, name: "bulbasaur", sprites: { front_default: "" }, types: [], height: 7, weight: 69, species: { url: "" } },
      { flavor_text_entries: [] }
    );

    render(<App />);
    await waitFor(() => {
      expect(screen.getByText(/bulbasaur/i)).toBeInTheDocument();
    });

    // mock para quando clicar no botão
    mockFetchSuccess(
      { id: 1, name: "bulbasaur", sprites: { front_default: "" }, types: [], height: 7, weight: 69, species: { url: "" } },
      { flavor_text_entries: [] }
    );

    fireEvent.click(screen.getByText("Aleatório"));

    await waitFor(() => {
      expect(screen.getByText(/bulbasaur/i)).toBeInTheDocument();
    });
  });
});

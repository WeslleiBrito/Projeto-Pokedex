import { useState, useEffect } from "react";

const MAX_POKEMON = 1010;

type PokemonData = {
  id: number;
  name: string;
  sprites: {
    front_default: string | null;
    versions: {
      ["generation-v"]: {
        ["black-white"]: {
          animated: {
            front_default: string | null;
          };
        };
      };
    };
  };
  types: { type: { name: string } }[];
  height: number;
  weight: number;
  species: { url: string };
  description?: string;
};

async function fetchPokemon(pokemon: string | number): Promise<PokemonData | null> {
  try {
    const res = await fetch(
      `https://pokeapi.co/api/v2/pokemon/${pokemon.toString().toLowerCase()}`
    );
    if (!res.ok) return null;
    const data = await res.json();

    const speciesRes = await fetch(data.species.url);
    const speciesData = await speciesRes.json();
    type FlavorTextEntry = {
      flavor_text: string;
      language: { name: string };
    };

    const flavor = speciesData.flavor_text_entries.find(
      (entry: FlavorTextEntry) => entry.language.name === "en"
    );

    return {
      ...data,
      description: flavor
        ? flavor.flavor_text.replace(/\n|\f/g, " ")
        : "Sem descrição disponível.",
    };
  } catch {
    return null;
  }
}

export default function App() {
  const [searchPokemon, setSearchPokemon] = useState(1);
  const [inputValue, setInputValue] = useState("");
  const [poke, setPoke] = useState<PokemonData | null>(null);
  const [loading, setLoading] = useState(false);

  async function loadPokemon(pokemon: string | number) {
    setLoading(true);
    setPoke(null);
    const data = await fetchPokemon(pokemon);
    if (data?.id) setSearchPokemon(data.id);
    setPoke(data);
    setLoading(false);
  }

  useEffect(() => {
    loadPokemon(1);
  }, []);

  const sprite =
    poke?.sprites?.versions?.["generation-v"]["black-white"].animated
      .front_default || poke?.sprites?.front_default || "";

  const types = poke?.types?.map((t) => t.type.name).join(" / ") ?? "";
  const height = poke ? poke.height / 10 : null;
  const weight = poke ? poke.weight / 10 : null;

  return (
    <>
      <header className="header">
        <img src="/img/logo.png" alt="Pokédex Logo" className="logo" />
      </header>

      <main className="container">
        <section className="pokedex-card">
          <img
            src="/img/pokedex-bg.png"
            alt="Pokédex background"
            className="pokedex-bg"
          />

          <div className="pokemon-center">
            <img
              src={sprite}
              alt="Pokémon sprite"
              className="pokemon__image"
              style={{ display: sprite ? "block" : "none" }}
            />
            <h2 className="pokemon__data">
              <span className="pokemon__number">
                {poke ? `#${poke.id} ` : ""}
              </span>
              <span className="pokemon__name">
                {loading
                  ? "Loading..."
                  : poke?.name ?? "Pokémon não encontrado!"}
              </span>
            </h2>

            <div className="info-card">
              <p className="pokemon__type">{types ? `Type: ${types}` : ""}</p>
              <p className="pokemon__heightweight">
                {height && weight
                  ? `Height: ${height} m | Weight: ${weight} kg`
                  : ""}
              </p>
              <p className="pokemon__description">
                {poke?.description ?? ""}
              </p>
            </div>
          </div>

          <form
            className="form"
            aria-label="Search Pokémon"
            onSubmit={(e) => {
              e.preventDefault();
              if (inputValue.trim()) loadPokemon(inputValue);
              setInputValue("");
            }}
          >
            <input
              type="search"
              className="input__search"
              placeholder="                               Nome ou número do pokémon"
              required
              value={inputValue}
              onChange={(e) => setInputValue(e.target.value)}
            />
            <button type="submit" className="button btn-search">
              🔍
            </button>
          </form>

          <div className="buttons">
            <button
              className="button btn-prev"
              onClick={() => searchPokemon > 1 && loadPokemon(searchPokemon - 1)}
            >
              ⬅ Anterior
            </button>
            <button
              type="button"
              className="button btn-random"
              onClick={() => {
                const randomId = Math.floor(Math.random() * MAX_POKEMON) + 1;
                loadPokemon(randomId);
              }}
            >
              Aleatório
            </button>
            <button
              className="button btn-next"
              onClick={() => loadPokemon(searchPokemon + 1)}
            >
              Próximo ➡
            </button>
          </div>
        </section>
      </main>
    </>
  );
}

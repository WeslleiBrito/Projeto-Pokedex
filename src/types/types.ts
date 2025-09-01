export type PokemonData = {
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
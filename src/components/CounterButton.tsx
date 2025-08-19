import {useState} from "react";

type CounterButtonProps = {
    label?: string;
};


export function CounterButton({label = "Contar"}: CounterButtonProps) {
    const [count, setCount] = useState(0);

    return(
        <button
            onClick={() => setCount((c) => c + 1)}
            style={
                {
                    padding: "8px 16px",
                    fontSize: "1rem",
                    borderRadius: "8px",
                    background: "#4caf50",
                    color: "white",
                    border: "none",
                    cursor: "pointer"
                }
            }
        >
            {label}: {count}
        </button>
    );
}
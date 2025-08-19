import React from 'react';
import { render, screen, fireEvent} from "@testing-library/react";
import { describe, it, expect} from "vitest"
import {CounterButton} from '../../src/components/CounterButton'


describe("CounterButton component", () => {
    it("deve renderizar com o texto inicial", () => {
        render(<CounterButton />);
        expect(screen.getByText("Contar: 0")).toBeInTheDocument();
    });

    it("deve aceitar um label customizado", () => {
        render(<CounterButton label="Clique aqui" />);
        expect(screen.getByText("Clique aqui: 0")).toBeInTheDocument();
    });

    it("deve incrementar o contador quando clicado", () => {
        render(<CounterButton />);
        const button = screen.getByRole("button");
        fireEvent.click(button);
        fireEvent.click(button);
        expect(screen.getByText("Contar: 2")).toBeInTheDocument();
    })
})
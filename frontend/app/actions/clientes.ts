"use server";

import { revalidatePath } from "next/cache";
import { redirect } from "next/navigation";
import {
  actualizarCliente,
  eliminarCliente,
  registrarCliente,
} from "@/lib/api/clientes";
import { parseNumber, parseText } from "@/app/actions/helpers";

export async function crearClienteAction(formData: FormData): Promise<void> {
  const dni = parseText(formData.get("dni"), "dni");
  const nombre = parseText(formData.get("nombre"), "nombre");
  const apellidos = parseText(formData.get("apellidos"), "apellidos");

  await registrarCliente({ dni, nombre, apellidos, carritos: [] });
  revalidatePath("/clientes");
  redirect("/clientes");
}

export async function editarClienteAction(formData: FormData): Promise<void> {
  const id = parseNumber(formData.get("id"), "id");
  const dni = parseText(formData.get("dni"), "dni");
  const nombre = parseText(formData.get("nombre"), "nombre");
  const apellidos = parseText(formData.get("apellidos"), "apellidos");

  await actualizarCliente({ id, dni, nombre, apellidos, carritos: [] });
  revalidatePath("/clientes");
  revalidatePath("/carrito");
  redirect("/clientes");
}

export async function eliminarClienteAction(formData: FormData): Promise<void> {
  const id = parseNumber(formData.get("id"), "id");
  await eliminarCliente(id);
  revalidatePath("/clientes");
  revalidatePath("/carrito");
  revalidatePath("/ordenes");
  redirect("/clientes");
}

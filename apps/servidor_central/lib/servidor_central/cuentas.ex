defmodule ServidorCentral.Cuentas do
  @moduledoc """
  Contexto para la gestión de usuarios del sistema.
  Expone las operaciones de registro, autenticación y consulta de usuarios.
  """

  alias ServidorCentral.{Repo, Usuario}
  import Ecto.Query

  @doc """
  Registra un nuevo usuario en el sistema.
  Recibe un mapa con los datos del usuario y retorna {:ok, usuario} o {:error, changeset}.
  """

  def registrar_usuario(params) do
    %Usuario{}
    |> Usuario.changeset_registro(params)
    |> Repo.insert()
  end

  @doc """
  Autentica un usuario por email y contraseña.
  Retorna {:ok, usuario} si las credenciales son correctas, {:error, :no_encontrado} si el email no existe,
  o {:error, :password_invalida} si la contraseña no coincide.
  """
  def login(email, password) do
    case Repo.get_by(Usuario, email: email) do
      nil ->
        Pbkdf2.no_user_verify()
        {:error, :no_encontrado}

      usuario ->
        if Pbkdf2.verify_pass(password, usuario.password_hash) do
          {:ok, usuario}
        else
          {:error, :password_invalida}
        end
    end
  end

  @doc """
  Busca un usuario por su id.
  """
  def buscar_por_id(id) do
    case Repo.get(Usuario, id) do
      nil -> {:error, :no_encontrado}
      usuario -> {:ok, usuario}
    end
  end

  @doc """
  Busca un usuario por su cédula.
  """
  def buscar_por_cedula(cedula) do
    case Repo.get_by(Usuario, cedula: cedula) do
      nil -> {:error, :no_encontrado}
      usuario -> {:ok, usuario}
    end
  end

  @doc """
  Lista todos los usuarios del sistema.
  """
  def listar_usuarios do
    Repo.all(Usuario)
  end

  @doc """
  Lista usuarios filtrados por rol.
  """
  def listar_por_rol(rol) do
    Usuario
    |> where([u], u.rol == ^rol)
    |> Repo.all()
  end

  @doc """
  Actualiza los datos de un usuario existente.
  """
  def actualizar_usuario(usuario, params) do
    usuario
    |> Usuario.changeset_actualizacion(params)
    |> Repo.update()
  end

  @doc """
  Elimina un usuario del sistema.
  Falla si el usuario tiene compras asociadas (por la constraint on_delete: :restrict).
  """
  def eliminar_usuario(id) do
    case buscar_por_id(id) do
      {:ok, usuario} -> Repo.delete(usuario)
      error -> error
    end
  end
end

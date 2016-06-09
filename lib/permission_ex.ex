defmodule PermissionEx do
  @moduledoc """
  Main module and interface to testing permissions.
  """


  @doc ~S"""
  This takes a `map` of permissions with the keys being a tag to be looked up
  on.  The required permission first element is the tag to match on.

  In the key of `:admin`, if `true`, will always return true no matter what the
  required matcher wants, it is an override that allows all permissions.

  If the key of `:admin` contains a map, then the tag will be looked up in it
  and tested against, such as if `true` then they will get permission for that
  tag regardless.

  If a given tag has the boolean of 'true' then it will always return true,
  basically giving admin just for that specific tag.

  ## Examples

    ```elixir

    iex> PermissionEx.test_struct_permissions(%PermissionEx.Test.Structs.Page{}, %{admin: true})
    true

    iex> %PermissionEx.Test.Structs.Page{action: :show}
    %PermissionEx.Test.Structs.Page{action: :show}

    iex> PermissionEx.test_struct_permissions(%PermissionEx.Test.Structs.Page{}, %{admin: %{PermissionEx.Test.Structs.Page => true}})
    true

    iex> PermissionEx.test_struct_permissions(%PermissionEx.Test.Structs.User{}, %{admin: %{PermissionEx.Test.Structs.Page => true}})
    false

    iex> PermissionEx.test_struct_permissions(%PermissionEx.Test.Structs.Page{action: :show}, %{PermissionEx.Test.Structs.Page => true})
    true

    iex> PermissionEx.test_struct_permissions(%PermissionEx.Test.Structs.Page{action: :show}, %{PermissionEx.Test.Structs.Page => %{}})
    false

    iex> PermissionEx.test_struct_permissions(%PermissionEx.Test.Structs.Page{action: :show}, %{PermissionEx.Test.Structs.Page => %{}})
    false

    iex> PermissionEx.test_struct_permissions(%PermissionEx.Test.Structs.Page{action: :show}, %{PermissionEx.Test.Structs.Page => %PermissionEx.Test.Structs.User{action: :show}})
    true

    iex> PermissionEx.test_struct_permissions(%PermissionEx.Test.Structs.Page{action: :show}, %{PermissionEx.Test.Structs.Page => %PermissionEx.Test.Structs.User{ action: :_}})
    true

    ```

  """
  def test_struct_permissions(_required, %{admin: true}), do: true
  # def test_taggedlist_permissions([tag | required], %{admin: %{} = admin_tags} = tagged_perm_group) do
  def test_struct_permissions(%{__struct__: tag} = required, %{admin: %{} = admin_tags} = tagged_perm_group) do
    #perms = Map.get_lazy(admin_tags, tag, fn -> Map.get(tagged_perm_group, tag, %{}) end)
    # TODO:  Perhaps add a blacklist permission here too?
    case test_permissions(required, Map.get(admin_tags, tag, nil)) do
      true -> true
      false -> test_permissions(required, Map.get(tagged_perm_group, tag, nil))
    end
  end
  # def test_taggedlist_permissions([tag | required], %{} = tagged_perm_group) do
  def test_struct_permissions(%{__struct__: tag} = required, %{} = tagged_perm_group) do
    test_permissions(required, Map.get(tagged_perm_group, tag, nil))
  end


  def test_permissions(required, permissions)
  def test_permissions(_required, true)  ,do: true
  def test_permissions(_required, false) ,do: false
  def test_permissions(_required, nil)   ,do: false
  # def test_permissions(_required, []), do: false

  def test_permissions(required, %{} = perms) do
    required
    |> Map.from_struct
    |> Enum.any?(fn {tag, req} ->
      perm = Map.get(perms, tag, nil)
      test_permission(req, perm)
    end)
  end
  # def test_permissions(required, [permission|rest]) do
  #   case test_permission(required, permission) do
  #     true -> true
  #     false -> test_permissions(required, rest)
  #   end
  # end

  def test_permission(required, permission)
  def test_permission(:_, _perm) ,do: true
  def test_permission(_req, :_)  ,do: true
  def test_permission(req, req)  ,do: true
  def test_permission(_required, _permission) do
    false
  end

end

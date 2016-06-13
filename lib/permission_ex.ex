defmodule PermissionEx do
  @moduledoc """
  Main module and interface to testing permissions.

  If you wish to test a single permission for equality, then you would use
  `PermissionEx.test_permission/2`.

  If you wish to test an entire permission struct for matching allowed
  permissions then you would use `PermissionEx.test_permissions/2`.

  If you wish to test an entire permission struct for matching allowed
  permissions on a struct tagged map then you would use
  `PermissionEx.test_tagged_permissions/2`.

  The examples in this module use these definitions of structs for testing
  permissions:

  ```elixir

  defmodule PermissionEx.Test.Structs.User do
    @moduledoc false
    @derive [Poison.Encoder]
    defstruct name: nil
  end

  defmodule PermissionEx.Test.Structs.Page do
    @moduledoc false
    @derive [Poison.Encoder]
    defstruct action: nil
  end

  defmodule PermissionEx.Test.Structs.PageReq do
    @moduledoc false
    @derive [Poison.Encoder]
    defstruct action: nil
  end

  defmodule PermissionEx.Test.Structs.PagePerm do
    @moduledoc false
    @derive [Poison.Encoder]
    defstruct action: nil
  end

  ```
  """


  @typedoc """
  A Permission matcher is either anything, of which it must then match the
  required permission precisely, or it is a tuple of `[:any | permissions]` where
  each item in the list will be tested against the requirement as a base
  permission, if any are true then this matches.
  """
  @type permission :: [:any | permission] | any


  @typedoc """
  This is a set of permissions such as %{}, [%{}], etc...

  A `:_` or `true` matches any entire requirement set.

  A `false` or `nil` will always not match.

  A list of `permissions` will each be checked individually against the
  requirement, if any are a true match then it returns true.

  A struct or map will be tested against the requirements directly, a struct is
  treated like a map except the `:__struct__` field will not be tested, useful
  if you want a requirement and permission to use different structs.  Do note
  that the `tagged_permissions` keys should match the `:__struct__` of the
  requirement struct, not of the permission struct.  I.E. given a
  `PermissionEx.Test.Structs.PageReq` and a
  `PermissionEx.Test.Structs.PagePerm`, such as if you want the default values
  for the requirement stuct to be by default tight or lenient, and the opposite
  for the permission struct, then calling `PermissionEx.test_permissions/2` will
  be like:

  ```elixir

  iex> PermissionEx.test_tagged_permissions(%PermissionEx.Test.Structs.PageReq{action: :show}, %{PermissionEx.Test.Structs.PageReq => [%PermissionEx.Test.Structs.PagePerm{action: :_}]})
  true

  iex> PermissionEx.test_tagged_permissions(%PermissionEx.Test.Structs.PageReq{action: :show}, %{PermissionEx.Test.Structs.PagePerm => [%PermissionEx.Test.Structs.PagePerm{action: :_}]})
  false

  ```
  """
  @type permissions :: :_ | boolean | nil | [permissions] | %{any => permission} | struct


  @typedoc """
  This is a map that has a mapping of a %{Struct => %Struct{}}.

  The value being an actual struct is optional, it can also be a map on its own,
  as long as it has matching keys => values of the struct, any missing will have
  the requirement be false unless the requirement is `:_`.

  If there is an `:admin` key in the permissions, then this is checked first and
  can act as an easy override for the main permission set.
  """
  @type tagged_permissions :: struct | %{:admin => tagged_permissions, atom => permissions} | %{atom => permissions}


  @doc ~S"""
  This takes a `map` of permissions with the keys being a tag to be looked up
  on.  The required permission struct type is the tag to match on.

  In the key of `:admin`, if `true`, will always return true no matter what the
  required matcher wants, it is an override that allows all permissions.

  If the key of `:admin` contains a map, then the tag will be looked up in it
  and tested against, such as if `true` then they will get permission for that
  tag regardless.

  If a given tag has the boolean of 'true' then it will always return true,
  basically giving admin just for that specific tag.

  See `PermissionEx.test_permissions/2` for how a permission struct/map is matched.

  See `PermissionEx.test_permission/2` for possible permission formats.

  ## Examples

    ```elixir

    iex> PermissionEx.test_tagged_permissions(%PermissionEx.Test.Structs.Page{}, %{admin: true})
    true

    iex> PermissionEx.test_tagged_permissions(%PermissionEx.Test.Structs.Page{}, %{admin: %{PermissionEx.Test.Structs.Page => true}})
    true

    iex> PermissionEx.test_tagged_permissions(%PermissionEx.Test.Structs.User{}, %{admin: %{PermissionEx.Test.Structs.Page => true}})
    false

    iex> PermissionEx.test_tagged_permissions(%PermissionEx.Test.Structs.Page{action: :show}, %{admin: %{PermissionEx.Test.Structs.Page => %{action: :show}}})
    true

    iex> PermissionEx.test_tagged_permissions(%PermissionEx.Test.Structs.Page{action: :edit}, %{admin: %{PermissionEx.Test.Structs.Page => %{action: :show}}})
    false

    iex> PermissionEx.test_tagged_permissions(%PermissionEx.Test.Structs.Page{action: :show}, %{PermissionEx.Test.Structs.Page => true})
    true

    iex> PermissionEx.test_tagged_permissions(%PermissionEx.Test.Structs.Page{action: :show}, %{PermissionEx.Test.Structs.Page => %{}})
    false

    iex> PermissionEx.test_tagged_permissions(%PermissionEx.Test.Structs.Page{action: :show}, %{PermissionEx.Test.Structs.Page => %{}})
    false

    iex> PermissionEx.test_tagged_permissions(%PermissionEx.Test.Structs.Page{action: :show}, %{PermissionEx.Test.Structs.Page => %PermissionEx.Test.Structs.Page{action: :show}})
    true

    iex> PermissionEx.test_tagged_permissions(%PermissionEx.Test.Structs.Page{action: :show}, %{PermissionEx.Test.Structs.Page => %PermissionEx.Test.Structs.Page{action: :_}})
    true

    iex> PermissionEx.test_tagged_permissions(%PermissionEx.Test.Structs.Page{action: :show}, %{PermissionEx.Test.Structs.Page => %PermissionEx.Test.Structs.Page{action: nil}})
    false

    iex> PermissionEx.test_tagged_permissions(%PermissionEx.Test.Structs.Page{action: :show}, %{PermissionEx.Test.Structs.Page => [%PermissionEx.Test.Structs.Page{action: :show}]})
    true

    iex> PermissionEx.test_tagged_permissions(%PermissionEx.Test.Structs.Page{action: :show}, %{PermissionEx.Test.Structs.Page => [%PermissionEx.Test.Structs.Page{action: :_}]})
    true

    iex> PermissionEx.test_tagged_permissions(%PermissionEx.Test.Structs.Page{action: :show}, %{PermissionEx.Test.Structs.Page => [%PermissionEx.Test.Structs.Page{action: nil}]})
    false

    iex> PermissionEx.test_tagged_permissions(%PermissionEx.Test.Structs.PageReq{action: :show}, %{PermissionEx.Test.Structs.PageReq => [%PermissionEx.Test.Structs.PagePerm{action: :_}]})
    true

    iex> PermissionEx.test_tagged_permissions(%PermissionEx.Test.Structs.PageReq{action: :show}, %{PermissionEx.Test.Structs.PagePerm => [%PermissionEx.Test.Structs.PagePerm{action: :_}]})
    false

    ```

  """
  @spec test_tagged_permissions(struct, tagged_permissions) :: boolean
  def test_tagged_permissions(required, tagged_perm_map)
  def test_tagged_permissions(_required, %{admin: true}), do: true
  def test_tagged_permissions(%{__struct__: tag} = required, %{admin: %{} = admin_tags} = tagged_perm_map) do
    #perms = Map.get_lazy(admin_tags, tag, fn -> Map.get(tagged_perm_map, tag, %{}) end)
    # TODO:  Perhaps add a blacklist permission here too?
    case test_permissions(required, Map.get(admin_tags, tag, nil)) do
      true -> true
      false -> test_permissions(required, Map.get(tagged_perm_map, tag, nil))
    end
  end
  def test_tagged_permissions(%{__struct__: tag} = required, %{} = tagged_perm_map) do
    test_permissions(required, Map.get(tagged_perm_map, tag, nil))
  end


  @doc ~S"""
   This tests a specific requirement against a set of permission.

   See `PermissionEx.test_permission/2` for possible permission formats.

  ## Examples

    ```elixir

    iex> PermissionEx.test_permissions(%PermissionEx.Test.Structs.Page{action: :show}, :_)
    true

    iex> PermissionEx.test_permissions(%PermissionEx.Test.Structs.Page{action: :show}, true)
    true

    iex> PermissionEx.test_permissions(%PermissionEx.Test.Structs.Page{action: :show}, false)
    false

    iex> PermissionEx.test_permissions(%PermissionEx.Test.Structs.Page{action: :show}, nil)
    false

    iex> PermissionEx.test_permissions(%PermissionEx.Test.Structs.Page{action: :show}, [])
    false

    iex> PermissionEx.test_permissions(%PermissionEx.Test.Structs.Page{action: :show}, %{})
    false

    iex> PermissionEx.test_permissions(%PermissionEx.Test.Structs.Page{action: :show}, %{action: :edit})
    false

    iex> PermissionEx.test_permissions(%PermissionEx.Test.Structs.Page{action: :show}, %{action: :show})
    true

    iex> PermissionEx.test_permissions(%PermissionEx.Test.Structs.Page{action: :show}, %{action: :_})
    true

    iex> PermissionEx.test_permissions(%PermissionEx.Test.Structs.Page{action: :show}, %{action: true})
    false

    iex> PermissionEx.test_permissions(%PermissionEx.Test.Structs.Page{action: :show}, %{action: [:any, :edit, :show]})
    true

    iex> PermissionEx.test_permissions(%PermissionEx.Test.Structs.Page{action: :show}, %PermissionEx.Test.Structs.Page{})
    false

    iex> PermissionEx.test_permissions(%PermissionEx.Test.Structs.Page{action: :show}, %PermissionEx.Test.Structs.Page{action: :edit})
    false

    iex> PermissionEx.test_permissions(%PermissionEx.Test.Structs.Page{action: :show}, %PermissionEx.Test.Structs.Page{action: :show})
    true

    iex> PermissionEx.test_permissions(%PermissionEx.Test.Structs.Page{action: :show}, %PermissionEx.Test.Structs.Page{action: :_})
    true

    iex> PermissionEx.test_permissions(%PermissionEx.Test.Structs.Page{action: :show}, %PermissionEx.Test.Structs.Page{action: true})
    false

    iex> PermissionEx.test_permissions(%PermissionEx.Test.Structs.Page{action: :show}, %PermissionEx.Test.Structs.Page{action: [:any, :edit, :show]})
    true

    iex> PermissionEx.test_permissions(%PermissionEx.Test.Structs.Page{action: :show}, [:_])
    true

    iex> PermissionEx.test_permissions(%PermissionEx.Test.Structs.Page{action: :show}, [true])
    true

    iex> PermissionEx.test_permissions(%PermissionEx.Test.Structs.Page{action: :show}, [false])
    false

    iex> PermissionEx.test_permissions(%PermissionEx.Test.Structs.Page{action: :show}, [nil])
    false

    iex> PermissionEx.test_permissions(%PermissionEx.Test.Structs.Page{action: :show}, [[]])
    false

    iex> PermissionEx.test_permissions(%PermissionEx.Test.Structs.Page{action: :show}, [%{}])
    false

    iex> PermissionEx.test_permissions(%PermissionEx.Test.Structs.Page{action: :show}, [%{action: :edit}])
    false

    iex> PermissionEx.test_permissions(%PermissionEx.Test.Structs.Page{action: :show}, [%{action: :show}])
    true

    iex> PermissionEx.test_permissions(%PermissionEx.Test.Structs.Page{action: :show}, [%{action: :_}])
    true

    iex> PermissionEx.test_permissions(%PermissionEx.Test.Structs.Page{action: :show}, [%{action: true}])
    false

    iex> PermissionEx.test_permissions(%PermissionEx.Test.Structs.Page{action: :show}, [%{action: [:any, :edit, :show]}])
    true

    iex> PermissionEx.test_permissions(%PermissionEx.Test.Structs.Page{action: :show}, [%PermissionEx.Test.Structs.Page{}])
    false

    iex> PermissionEx.test_permissions(%PermissionEx.Test.Structs.Page{action: :show}, [%PermissionEx.Test.Structs.Page{action: :edit}])
    false

    iex> PermissionEx.test_permissions(%PermissionEx.Test.Structs.Page{action: :show}, [%PermissionEx.Test.Structs.Page{action: :show}])
    true

    iex> PermissionEx.test_permissions(%PermissionEx.Test.Structs.Page{action: :show}, [%PermissionEx.Test.Structs.Page{action: :_}])
    true

    iex> PermissionEx.test_permissions(%PermissionEx.Test.Structs.Page{action: :show}, [%PermissionEx.Test.Structs.Page{action: true}])
    false

    iex> PermissionEx.test_permissions(%PermissionEx.Test.Structs.Page{action: :show}, [%PermissionEx.Test.Structs.Page{action: [:any, :edit, :show]}])
    true

    ```
  """
  @spec test_permissions(struct, permissions) :: boolean
  def test_permissions(required, permissions)
  def test_permissions(_required, :_)    ,do: true
  def test_permissions(_required, true)  ,do: true
  def test_permissions(_required, false) ,do: false
  def test_permissions(_required, nil)   ,do: false
  def test_permissions(_required, [])    ,do: false
  def test_permissions(_required, %{}=m) when map_size(m)==0, do: false
  def test_permissions(required, [permissions | rest]) do
    case test_permissions(required, permissions) do
      true -> true
      false -> test_permissions(required, rest)
    end
  end
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


  @doc ~S"""
   This tests a specific required permission against a specific permission.

   * If either are `:_` then it is true.
   * If both are identical, then it is true.
   * If the permission is the tuple `{:any, [<permissions>]}` then each
     permission in the list is tested against the requirement

  ## Examples

    ```elixir

    iex> PermissionEx.test_permission(:_, :_)
    true

    iex> PermissionEx.test_permission(:_, nil)
    true

    iex> PermissionEx.test_permission(nil, :_)
    true

    iex> PermissionEx.test_permission(nil, nil)
    true

    iex> PermissionEx.test_permission(nil, :notnil)
    false

    iex> PermissionEx.test_permission(:notnil, nil)
    false

    iex> PermissionEx.test_permission(1, 1)
    true

    iex> PermissionEx.test_permission(1, 1.0)
    false

    iex> PermissionEx.test_permission('test', 'test')
    true

    iex> PermissionEx.test_permission("test", "test")
    true

    iex> PermissionEx.test_permission('test', "test")
    false

    iex> PermissionEx.test_permission(:show, :show)
    true

    iex> PermissionEx.test_permission(:show, :edit)
    false

    iex> PermissionEx.test_permission(:show, [:any])
    false

    iex> PermissionEx.test_permission(:show, [:any, :show])
    true

    iex> PermissionEx.test_permission(:show, [:any, :show, :edit])
    true

    iex> PermissionEx.test_permission(:show, [:any, :edit, :show])
    true

    iex> PermissionEx.test_permission(:show, [:any, :edit, :otherwise])
    false

    iex> PermissionEx.test_permission(:show, ["any"])
    false

    iex> PermissionEx.test_permission(:show, ["any", :show])
    true

    iex> PermissionEx.test_permission(:show, ["any", :show, :edit])
    true

    iex> PermissionEx.test_permission(:show, ["any", :edit, :show])
    true

    iex> PermissionEx.test_permission(:show, ["any", :edit, :otherwise])
    false

    iex> PermissionEx.test_permission(:show, ["any", "edit", "show"])
    true

    iex> PermissionEx.test_permission(:show, ["any", "edit", "otherwise"])
    false

    iex> PermissionEx.test_permission(:show, "show")
    true

    ```
  """
  @spec test_permission(any, permission) :: boolean
  def test_permission(required, permission)
  def test_permission(:_, _perm)        ,do: true
  def test_permission(_req, :_)         ,do: true
  def test_permission(req, req)         ,do: true
  def test_permission(_req, [:any])     ,do: false
  def test_permission(_req, [])         ,do: false

  def test_permission(req, perm) when is_atom(req) and is_binary(perm) do
    to_string(req) === perm
  end

  def test_permission(_req, "_")        ,do: true # test_permission(req, :_)
  def test_permission(req, ["any"|p])   ,do: test_permission(req, [:any|p])

  def test_permission(required, [:any, permission | rest]) do
    case test_permission(required, permission) do
      true -> true
      false -> test_permission(required, [:any | rest])
    end
  end

  def test_permission(_required, _permission) do
    false
  end

end

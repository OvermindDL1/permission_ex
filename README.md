# PermissionEx

A simple Struct-based Permission system for Elixir.  Created to be used with
Phoenix but has no requirement or any real integration with it as this is
designed to be entirely generic.

## Installation

[Available in Hex](https://hex.pm/packages/permission_ex), the package can be
installed by:

  1. Add permission_ex to your list of dependencies in `mix.exs`:

    ```elixir
    def deps do
      [{:permission_ex, "~> 0.0.1"}]
    end
```



## Features

This is the current feature set of what is done, planned, and thought about.  If
any feature is not done yet or if any feature wants to be added that is not on
this list then please open an issue and/or pull request to have it get done
faster.


  - [x] Permission Matcher to test permissions against a requirement.
  - [x] Admin Permission Matcher to pre-authorize before testing normal permissions.
  - [ ] Maybe add some more Permission specialties, such as maybe a `{:range, lower, upper}` test, maybe a function call test?
  - [ ] Maybe add helpers for serializing the structs to/from json by using Poison.
  - [ ] Maybe add helpers to serialize the structs in other ways?  If so then into what ways?
  - [ ] Maybe a deny Permission Matcher to hard deny before admin is tested.
  - [ ] Maybe add support to take a list of requirements and test each so all must have a match.
  - [ ] Maybe Create plugs to test permissions and either set a variable or kill/redirect the plug chain.




## Usage

General usage will usually be something like reading either a tagged map or a
specific permission set from, say, a database or elsewhere, then comparing it to
a specific requirement.

For example, say you have this phoenix controller method:
```elixir
  def show(conn, _params) do
    conn
    |> render("index.html")
  end
```

And if you have a permission set from the logged in user (or you can pre-fill an
anonymous user permission set, or leave empty if anon should have no access to
anything), say you have it on `conn.assigns.perms` and it is a tagged map, then
you could test it like this:
```elixir
  def show(conn, _params) do
    if PermissionEx.test_tagged_permissions(MyApp.Perms.IndexPage{action: :show}, conn.assigns.perms) do
      conn
      |> render("index.html")
    else
      conn
      |> render("unauthorized.html")
    end
  end
```



## Examples

Please see `PermissionEx` for detailed examples.

All of the examples use these as the example structs:

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

### Testing a specific permission:  `PermissionEx.test_permission/2`

The required permission is the first argument, the allowed permission is on the
right.  Normal usage would be something like:

```elixir
permissions = [:show, :edit] # From somewhere else
PermissionEx.test_permission(:show, permissions) # Returns true
PermissionEx.test_permission(:admin, permissions) # Returns true
```

  * Identical things match:
    ```elixir
    iex> PermissionEx.test_permission(:anything_identical, :anything_identical)
    true

    iex> PermissionEx.test_permission("anything identical", "anything identical")
    true
```

  * Anything matches the atom `:_`:
    ```elixir
    iex> PermissionEx.test_permission(:_, :_)
    true

    iex> PermissionEx.test_permission(:_, :anything)
    true

    iex> PermissionEx.test_permission(:anything, :_)
    true
```

  * If the permission is a `{:any, [permissions]}` then each permission in the
    list will be tested individually for if they match the requirement, and if
    any test true then this will be true.
    ```elixir
    iex> PermissionEx.test_permission(:show, {:any, []})
    false

    iex> PermissionEx.test_permission(:show, {:any, [:show]})
    true

    iex> PermissionEx.test_permission(:show, {:any, [:show, :edit]})
    true

    iex> PermissionEx.test_permission(:show, {:any, [:edit, :show]})
    true

    iex> PermissionEx.test_permission(:show, {:any, [:edit, :otherwise]})
    false
```



### Testing a permission set against a requirement struct: `PermissionEx.test_permissions/2`

You can test a struct requirement against a permission map or list or maps or
even against override values such as in:

  * Via an override, where `true` or `:_` allows the entire requirement,
    and where `false`, `nil`, an empty list `[]`, or an empty map or struct
    `%{}` return false:
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
```

  * Or via a map or struct, structs tend to be better if the default values
    for the struct align with the needs better, if anything in a map is
    missing that a requirement tests for then it will return false:
    ```elixir
    iex> PermissionEx.test_permissions(%PermissionEx.Test.Structs.Page{action: :show}, %{action: :_})
    true

    iex> PermissionEx.test_permissions(%PermissionEx.Test.Structs.Page{action: :show}, %{action: true})
    false

    iex> PermissionEx.test_permissions(%PermissionEx.Test.Structs.Page{action: :show}, %{action: {:any, [:edit, :show]}})
    true

    iex> PermissionEx.test_permissions(%PermissionEx.Test.Structs.Page{action: :show}, %PermissionEx.Test.Structs.Page{})
    false

    iex> PermissionEx.test_permissions(%PermissionEx.Test.Structs.Page{action: :show}, %PermissionEx.Test.Structs.Page{action: :edit})
    false

    iex> PermissionEx.test_permissions(%PermissionEx.Test.Structs.Page{action: :show}, %PermissionEx.Test.Structs.Page{action: :show})
    true
  ```

  * Or a list of any of the above, any overrides, maps, or structs:
    ```elixir
    iex> PermissionEx.test_permissions(%PermissionEx.Test.Structs.Page{action: :show}, [true])
    true

    iex> PermissionEx.test_permissions(%PermissionEx.Test.Structs.Page{action: :show}, [false])
    false

    iex> PermissionEx.test_permissions(%PermissionEx.Test.Structs.Page{action: :show}, [%{action: :edit}])
    false

    iex> PermissionEx.test_permissions(%PermissionEx.Test.Structs.Page{action: :show}, [%{action: :show}])
    true

    iex> PermissionEx.test_permissions(%PermissionEx.Test.Structs.Page{action: :show}, [%PermissionEx.Test.Structs.Page{action: :edit}])
    false

    iex> PermissionEx.test_permissions(%PermissionEx.Test.Structs.Page{action: :show}, [%PermissionEx.Test.Structs.Page{action: :show}])
    true
```



### Testing a tagged permission set against a requirement struct: `PermissionEx.test_tagged_permissions/2`

You can test a struct requirement against a map of permissions keyed on the
requirement structs `:__struct__` value.

There is also an override key of `:admin`, this is another tagged permission map
or an override that is tested before the main permissions are tested.

  * The permission map is just a map of the permission sets, so for example:
    ```elixir
    iex> PermissionEx.test_tagged_permissions(%PermissionEx.Test.Structs.Page{action: :show}, %{PermissionEx.Test.Structs.Page => %{}})
    false

    iex> PermissionEx.test_tagged_permissions(%PermissionEx.Test.Structs.Page{action: :show}, %{PermissionEx.Test.Structs.Page => %PermissionEx.Test.Structs.Page{action: :show}})
    true

    iex> PermissionEx.test_tagged_permissions(%PermissionEx.Test.Structs.Page{action: :show}, %{PermissionEx.Test.Structs.Page => %PermissionEx.Test.Structs.Page{action: :_}})
    true

    iex> PermissionEx.test_tagged_permissions(%PermissionEx.Test.Structs.Page{action: :show}, %{PermissionEx.Test.Structs.Page => %PermissionEx.Test.Structs.Page{action: nil}})
    false
```

  * Do note, the permission map is keyed on the requirement struct, not on the
    struct of its value, this allows you to define a different struct for the
    permission side that could have certain default values to be set to what you
    want, such as in:
    ```elixir
    iex> PermissionEx.test_tagged_permissions(%PermissionEx.Test.Structs.PageReq{action: :show}, %{PermissionEx.Test.Structs.PageReq => [%PermissionEx.Test.Structs.PagePerm{action: :_}]})
    true

    iex> PermissionEx.test_tagged_permissions(%PermissionEx.Test.Structs.PageReq{action: :show}, %{PermissionEx.Test.Structs.PagePerm => [%PermissionEx.Test.Structs.PagePerm{action: :_}]})
    false
```

  * If there is an `:admin` key on the struct, then it is checked first, this
    allows you to set up easy overrides for all or specific matches:
    ```elixir
    # Can override and allow absolutely everything by just setting admin: true
    iex> PermissionEx.test_tagged_permissions(%PermissionEx.Test.Structs.Page{}, %{admin: true})
    true

    # Or can set it on a specific struct, it will not affect others then:
    iex> PermissionEx.test_tagged_permissions(%PermissionEx.Test.Structs.Page{}, %{admin: %{PermissionEx.Test.Structs.Page => true}})
    true

    iex> PermissionEx.test_tagged_permissions(%PermissionEx.Test.Structs.User{}, %{admin: %{PermissionEx.Test.Structs.Page => true}})
    false

    # Can do fine-tuned matching as well if an override is needed, it will not allow non-matches
    iex> PermissionEx.test_tagged_permissions(%PermissionEx.Test.Structs.Page{action: :show}, %{admin: %{PermissionEx.Test.Structs.Page => %{action: :show}}})
    true

    iex> PermissionEx.test_tagged_permissions(%PermissionEx.Test.Structs.Page{action: :edit}, %{admin: %{PermissionEx.Test.Structs.Page => %{action: :show}}})
    false
```

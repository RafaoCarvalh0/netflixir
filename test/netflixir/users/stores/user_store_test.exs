defmodule Netflixir.Users.Stores.UserStoreTest do
  use Netflixir.DataCase, async: true
  import Netflixir.Factory

  alias Netflixir.Users.Stores.UserStore
  alias Netflixir.Users.Stores.Schemas.User

  describe "create_user/1" do
    test "creates a user with valid data" do
      attrs = params_for(:user, password: "supersecret")
      assert {:ok, %User{} = user} = UserStore.create_user(attrs)
      assert user.name == attrs.name
      assert user.email == attrs.email
      assert user.username == attrs.username
      assert Bcrypt.verify_pass(attrs.password, user.password_hash)
    end

    test "returns error with invalid data" do
      attrs = %{email: "", username: "", password: ""}
      assert {:error, changeset} = UserStore.create_user(attrs)
      errors = errors_on(changeset)
      assert Map.has_key?(errors, :name)
      assert Map.has_key?(errors, :email)
      assert Map.has_key?(errors, :username)
      assert Map.has_key?(errors, :password)
    end
  end

  describe "get_user_by_email/1" do
    test "returns user when email exists" do
      user = insert(:user, email: "test@example.com")
      assert %User{} = found = UserStore.get_user_by_email("test@example.com")
      assert found.id == user.id
    end

    test "returns nil when email does not exist" do
      assert UserStore.get_user_by_email("notfound@example.com") == nil
    end
  end

  describe "get_user_by_username/1" do
    test "returns user when username exists" do
      user = insert(:user, username: "uniqueuser")
      assert %User{} = found = UserStore.get_user_by_username("uniqueuser")
      assert found.id == user.id
    end

    test "returns nil when username does not exist" do
      assert UserStore.get_user_by_username("notfounduser") == nil
    end
  end

  describe "get_user_by_id/1" do
    test "returns user when id exists" do
      user = insert(:user)
      assert %User{} = found = UserStore.get_user_by_id(user.id)
      assert found.id == user.id
      assert found.email == user.email
      assert found.username == user.username
      assert found.name == user.name
    end

    test "returns nil when id does not exist" do
      assert UserStore.get_user_by_id(-123) == nil
    end
  end
end

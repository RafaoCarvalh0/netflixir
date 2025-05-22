defmodule NetflixirWeb.PageControllerTest do
  use NetflixirWeb.ConnCase

  alias Netflixir.StorageFixtures

  setup do
    StorageFixtures.setup_storage_mock_defaults()
    :ok
  end

  test "GET /", %{conn: conn} do
    conn = get(conn, ~p"/")
    assert html_response(conn, 200) =~ "Test Video 1"
  end
end

defmodule RelaxirWeb.IngredientLive.UploadTest do
  use RelaxirWeb.ConnCase, async: true

  import Relaxir.DataHelpers

  describe "handle_params/3" do
    test "updates ingredient image filename and redirects", %{conn: conn} do
      # Create a test user
      user = Relaxir.AccountsFixtures.user_fixture(%{email: "user@example.com", password: "password123"})
      _conn = log_in_user(conn, user)

      # Create a test ingredient
      %{ingredient: ingredient} = ingredient(%{})

      # Create a socket with the necessary assigns
      socket = %Phoenix.LiveView.Socket{
        assigns: %{
          current_user: user
        }
      }

      # Call handle_params directly with valid parameters
      # This simulates being called as a callback from UploadLive
      {:noreply, updated_socket} = RelaxirWeb.IngredientLive.Upload.handle_params(
        %{"id" => Integer.to_string(ingredient.id), "image_filename" => "test.jpg"},
        "/ingredients/#{ingredient.id}/upload?image_filename=test.jpg",
        socket
      )

      # Verify it redirects to the ingredient page
      assert updated_socket.redirected == {:live, :patch, %{kind: :push, to: "/ingredients/#{ingredient.id}/#{ingredient.name |> String.replace(" ", "%20")}"}}

      # Verify the ingredient was updated with the image filename
      updated_ingredient = Relaxir.Ingredients.get_ingredient!(ingredient.id)
      assert updated_ingredient.image_filename == "test.jpg"
    end
  end
end

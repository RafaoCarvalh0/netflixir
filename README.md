# Netflixir

Um projeto de estudo pessoal que visa compreender e replicar as técnicas de streaming de vídeo utilizadas pela Netflix, implementado com Elixir e Phoenix LiveView.

## Sobre o Projeto

Este é um desafio pessoal para entender profundamente como funciona o processo de streaming adaptativo de vídeos, similar ao utilizado pela Netflix. O projeto utiliza Elixir para o backend devido à sua excelente capacidade de lidar com streams e concorrência, e Phoenix LiveView para criar uma interface reativa em tempo real.

### MVP (Minimum Viable Product)
- Streaming de vídeo com qualidade adaptativa baseada na conexão do usuário
- Interface para seleção manual da qualidade do vídeo

### Stack Tecnológica
- **Backend**: Elixir + Phoenix
- **Frontend**: Phoenix LiveView + TailwindCSS
- **Processamento de Vídeo**: FFmpeg
- **Banco de Dados**: PostgreSQL

### Nota sobre o Frontend
quase toda interface do usuário foi desenvolvida com auxílio de IA, já que o foco principal do projeto é a implementação do backend e o entendimento do processo de streaming. O design foi inspirado na interface da Netflix.

## Pré-requisitos

  * Elixir e Erlang instalados (recomendado via `asdf install`)
  * FFmpeg instalado (necessário para processamento de vídeo)

## Configuração Inicial

1. Clone o repositório
2. Instale as dependências:
```bash
mix setup
```
3. Configure o banco de dados em `config/dev.exs`
4. Inicie o servidor:
```bash
mix phx.server
```

O servidor estará disponível em [`localhost:4000`](http://localhost:4000)

### (SERÁ DEPRECIADO) Caso deseje processar um video manualmente

1. Coloque seu vídeo MP4 na pasta `priv/static/uploads/raw/`, por exemplo: `meu_video.mp4`

2. (Opcional) Se desejar usar uma thumbnail personalizada, coloque uma imagem JPG com o mesmo nome base do vídeo em `priv/static/uploads/videos/thumbnails/`, exemplo: `meu_video.jpg`

3. Abra o console do IEx:
```bash
iex -S mix
```

4. Execute o processamento usando o StreamPackager:
```elixir
# No console do IEx
alias Netflixir.Videos.StreamPackager
StreamPackager.process_video("priv/static/uploads/raw/meu_video.mp4")
```

O StreamPackager irá automaticamente:
- Transcodificar o vídeo para um formato otimizado
- Criar múltiplas resoluções (1080p, 720p, 480p, 360p, 240p, 144p)
- Gerar os segmentos HLS e playlists
- Organizar os arquivos na estrutura correta para streaming

Após o processamento terminar, o vídeo já estará disponível para streaming adaptativo através da interface web em [`localhost:4000`](http://localhost:4000).


## Contribuições

Este é um projeto de estudo pessoal, mas sugestões e contribuições são bem-vindas! Sinta-se à vontade para abrir issues ou enviar pull requests.

## Aprendizados e Documentação

Para entender mais sobre as tecnologias utilizadas:

* [Phoenix Framework](https://www.phoenixframework.org/)
* [Phoenix LiveView](https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.html)
* [FFmpeg](https://ffmpeg.org/documentation.html)
* [HLS Streaming](https://developer.apple.com/streaming/)


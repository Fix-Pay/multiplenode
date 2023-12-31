#!/bin/bash

for i in {1..2}; do

  if [ $i -eq 1 ]; then
    URL=$API_URL
    API_KEY=$API_KEY
    STACK_NAME=$STACK_NAME1
    CONTAINER_NAME=$CONTAINER_NAME
    FILE_PATH=$FILE_PATH
    ENDPOINT=$ENDPOINT
    api_docker=$api_docker
    MANIPULA_CONTAINER=$api_docker/containers
    GET_IMAGE_SHA=$api_docker/images/json
    DELETE_IMAGE=$api_docker/images
    tags=$tags

    response=$(curl -k -X GET "$URL" -H "X-API-Key: $API_KEY" --insecure)
    echo "*******************************"
    echo "fim da chamada do response"
    echo "*******************************"
    # Faz a solicitação GET e armazena a resposta em uma variável
    response_get_sha=$(curl -k -X GET "$GET_IMAGE_SHA" -H "X-API-Key: $API_KEY")
      echo "*******************************"
      echo "fim da chamada do response do response_get_sha"
      echo "*******************************"
    # Obtenha o ID do contêiner com base no nome
    CONTAINER_ID=$(curl -s -k -X  GET "$MANIPULA_CONTAINER/json" -H "X-Api-Key: $API_KEY" | jq -r '.[] | select(.Names[] | contains("'$CONTAINER_NAME'")) | .Id' )

      echo "*******************************"
      echo "fim da chamada do CONTAINER_ID" $CONTAINER_ID
      echo "*******************************"

    IMAGE_SHA=$(echo "$response_get_sha" | jq -r '.[] | select(.RepoTags | index("'"$tags"'") // null != null) | .Id')

      echo "*******************************"
      echo "fim da chamada do IMAGEM_SHA" $IMAGE_SHA
      echo "*******************************"

    validar=$(echo "$response" | jq -e '.[] | select(.Name == "'"$STACK_NAME"'")' > /dev/null; echo $?)
    echo $validar

    # Verifica se a stack está criada
    if [ $validar -eq 0 ]; then

      # Extrai o valor do campo "Name" usando jq
      name=$(echo "$response" | jq -r '.[] | select(.Name == "'"$STACK_NAME"'") | .Name')

      # Imprime o nome da stack
      echo "A Stack chamada $name está criada."

      # Obtém o ID da stack
      id=$(echo "$response" | jq -r '.[] | select(.Name == "'"$STACK_NAME"'") | .Id')
      echo "Id da Stack: $id"
      
      # Monta a URL para a exclusão
      DELETE_URL="$URL/$id"
      
      # verifica se o container existe. 
      if [ ! -z "$CONTAINER_ID" ]; then
        echo "pausando container"
        curl -k -X POST "$MANIPULA_CONTAINER/$CONTAINER_NAME/stop" -H "X-API-Key: $API_KEY"
        sleep 5

        echo "deletando container"
        curl -k -X DELETE "$MANIPULA_CONTAINER/$CONTAINER_NAME" -H "X-API-Key: $API_KEY"
        sleep 5

        # VALIDAR PROCESSO DE EXCLUSAO DA IMAGEM
        echo "deletando imagem"
        curl -X  DELETE "$DELETE_IMAGE/$IMAGE_SHA" -H "X-API-Key: $API_KEY" --insecure
        sleep 5

        echo "deletando stack"
        curl -k -X DELETE "$DELETE_URL" \
        -H "X-API-Key: $API_KEY" \
        -F "type=2" \
        -F "method=file" \
        -F "file=@$FILE_PATH" \
        -F "endpointId=$ENDPOINT" \
        -F "Name=$STACK_NAME" --insecure
        echo "Stack deletada. ID: $id"

        echo "=========================================="
        echo "CRIANDO A STACK $name"
        echo "=========================================="
        response=$(curl -k -s -X POST "$URL" \
        -H "X-API-Key: $API_KEY" \
        -F "type=2" \
        -F "method=file" \
        -F "file=@$FILE_PATH" \
        -F "endpointId=$ENDPOINT" \
        -F "Name=$STACK_NAME" --insecure)

        # Imprimir a resposta da requisição 
        echo "Resposta da solicitação POST: $response"

        # Extrair o valor do campo "Id" da nova stack usando jq
        id=$(echo "$response" | jq -r '.Id')

        # Imprimir o valor do Id
        echo "Nova Stack criada. Id: $id"
      else
        echo "stack encontrada, mas container não encontrado"

        echo "deletando container"
        curl -k -X DELETE "$MANIPULA_CONTAINER/$CONTAINER_NAME" -H "X-API-Key: $API_KEY"
        sleep 5

        echo "deletando imagem"
        echo "================"
        curl -X DELETE "$DELETE_IMAGE/$IMAGE_SHA" -H "X-API-Key: $API_KEY" --insecure
        sleep 5
        
        echo "================"
        echo "DELETANDO STACK"
        echo "================"
        curl -X  DELETE "$DELETE_URL" \
        -H "X-API-Key: $API_KEY" \
        -F "type=2" \
        -F "method=file" \
        -F "file=@$FILE_PATH" \
        -F "endpointId=$ENDPOINT" \
        -F "Name=$STACK_NAME" --insecure
        echo "Stack deletada. ID: $id"

        echo "============================"
        echo "CRIANDO A STACK $name"
        echo "============================"
        response=$(curl -k -s -X POST "$URL" \
        -H "X-API-Key: $API_KEY" \
        -F "type=2" \
        -F "method=file" \
        -F "file=@$FILE_PATH" \
        -F "endpointId=$ENDPOINT" \
        -F "Name=$STACK_NAME" --insecure)
      fi

    else
      echo "======================================"
      echo "NENHUMA STACK DA APLICAÇÃO ENCONTRADA."
      echo "======================================"


      # VALIDAR PROCESSO DE EXCLUSAO DA IMAGEM
      echo "deletando imagem"
        curl -X  DELETE "$DELETE_IMAGE/$IMAGE_SHA" -H "X-API-Key: $API_KEY" --insecure
        sleep 5

      echo "CRIANDO A NOVA STACK"
      echo "======================================"
      response=$(curl -s -X POST "$URL" \
      -H "X-API-Key: $API_KEY" \
      -F "type=2" \
      -F "method=file" \
      -F "file=@$FILE_PATH" \
      -F "endpointId=$ENDPOINT" \
      -F "Name=$STACK_NAME" --insecure)

      # Imprimir a resposta da requisição 
      echo "Resposta da solicitação POST: $response"

      # Extrair o valor do campo "Id" da nova stack usando jq
      id=$(echo "$response" | jq -r '.Id')

      # Imprimir o valor do Id
      echo "Nova Stack criada. Id: $id"
    fi

  elif [ $i -eq 2 ]; then
    URL=$API_URL
    API_KEY=$API_KEY
    STACK_NAME=$STACK_NAME2
    FILE_PATH=$FILE_PATH
    ENDPOINT=$ENDPOINT2
    api_docker=$api_docker2
    MANIPULA_CONTAINER=$api_docker/containers
    GET_IMAGE_SHA=$api_docker/images/json
    DELETE_IMAGE=$api_docker/images
    tags=$tags

    #Faz a solicitação pra URL das stacks e armazena a resposta em uma variável
    response=$(curl -k -X GET "$URL" -H "X-API-Key: $API_KEY" --insecure)
    echo "*******************************"
    echo "fim da chamada do response"
    echo "*******************************"

    # Faz a solicitação GET para a URL das stacks e armazena a resposta do SHA da imagem em uma variável
    response_get_sha=$(curl -k -X GET "$GET_IMAGE_SHA" -H "X-API-Key: $API_KEY")
    echo "fim da chamada do response do response_get_sha"
    echo "*******************************"

    # Obter o ID do contêiner com base na stack
    CONTAINER_ID=$(curl -k -X  GET "$MANIPULA_CONTAINER/json" -H "X-Api-Key: $API_KEY" | jq -r '.[] | select(.Names[] | contains("'$STACK_NAME'")) | .Id' )
    echo $CONTAINER_ID
    echo "fim da chamada do CONTAINER_ID" 
    echo "*******************************"

    # Obeter o SHA da imagem do contêiner
    CONTAINER_IMAGE=$(curl -k -X GET "$MANIPULA_CONTAINER/$CONTAINER_ID/json" -H "X-Api-Key: $API_KEY" | jq -r '.Image')
    echo $CONTAINER_IMAGE
    echo "fim da chamada do CONTAINER_ID" 
    echo "*******************************"

    # Filtra todas as tags do portainer baseado no nome da tag que foi fornecida
    filtered_tags=$(echo "$response_get_sha" | jq -r '.[] | select(.RepoTags) | .RepoTags[] | select(startswith("'"$tags"'"))')

    echo $filtered_tags
    echo "fim da chamada do filtered_tags" 
    echo "*******************************"

    echo "Tags filtradas para a imagem $tags"
    for fil in $filtered_tags; do
        echo "- $fil"
    done

    #Validando se a stack existe
    validar=$(echo "$response" | jq -e '.[] | select(.Name == "'"$STACK_NAME"'")' > /dev/null; echo $?)

    # Verifica se a stack está criada. SE SIM
    if [ $validar -eq 0 ]; then
    
      # Extrai o valor do campo "Name" usando jq
      name=$(echo "$response" | jq -r '.[] | select(.Name == "'"$STACK_NAME"'") | .Name')
      echo "A Stack chamada $name está criada."

      # Obtém o ID da stack
      stack_id=$(echo "$response" | jq -r '.[] | select(.Name == "'"$STACK_NAME"'") | .Id')
      echo "O ID da stack $name é: $stack_id"

      # verifica se o container existe. SE SIM 
      if [ ! -z "$stack_id" ]; then

        echo "Solicitação para pausar a stack"
        curl -k -s -X POST "$URL/$stack_id/stop" \
          -H "X-API-Key: $API_KEY" \
          -F "type=2" \
          -F "method=file" \
          -F "file=@$FILE_PATH" \
          -F "endpointId=$ENDPOINT" \
          -F "Name=$STACK_NAME" --insecure
          echo "Stack pausada. :)"
        
        sleep 18

          echo "Deletando imagem"
          curl -X DELETE "$DELETE_IMAGE/$CONTAINER_IMAGE" -H "X-API-Key: $API_KEY" --insecure
          echo "Imagem deletada. :)"

        sleep 18

        echo "entrando no processo de start da stack"
          # Solicitação para startar a stack
          curl -k -s -X POST "$URL/$stack_id/start" \
            -H "X-API-Key: $API_KEY" \
            -F "type=2" \
            -F "method=file" \
            -F "file=@$FILE_PATH" \
            -F "endpointId=$ENDPOINT" \
              -F "Name=$STACK_NAME" --insecure
      else 
        echo "STACK ENCONTRADA, PORÉM O CONTAINER NÃO FOI ENCONTRADO"

        echo "Solicitação para pausar a stack"
        curl -k -s -X POST "$URL/$stack_id/stop" \
          -H "X-API-Key: $API_KEY" \
          -F "type=2" \
          -F "method=file" \
          -F "file=@$FILE_PATH" \
          -F "endpointId=$ENDPOINT" \
          -F "Name=$STACK_NAME" --insecure
          echo "Stack pausada. :)"
        
        sleep 18

        echo "Deletando imagens..."
        curl -X DELETE "$DELETE_IMAGE/$CONTAINER_IMAGE" -H "X-API-Key: $API_KEY" --insecure
        echo "Imagem deletada. :)"

        echo "entrando no processo de start da stack"
          # Solicitação para startar a stack
          curl -k -s -X POST "$URL/$stack_id/start" \
            -H "X-API-Key: $API_KEY" \
            -F "type=2" \
            -F "method=file" \
            -F "file=@$FILE_PATH" \
            -F "endpointId=$ENDPOINT" \
            -F "Name=$STACK_NAME" --insecure
      fi

    else
      echo "======================================"
      echo "NENHUMA STACK DA APLICAÇÃO ENCONTRADA."
      echo "======================================"

          # Deletando a imagem. 
      echo "Deletando imagens..."
      echo "Deletando imagem T_T"
      curl -X DELETE "$DELETE_IMAGE/$CONTAINER_IMAGE" -H "X-API-Key: $API_KEY" --insecure
      echo "Imagem deletada. :)"

      sleep 5  

      echo "CRIANDO A NOVA STACK"
      echo "======================================"
        response=$(curl -v -X POST "$URL" \
        -H "X-API-Key: $API_KEY" \
        -F "type=2" \
        -F "method=file" \
        -F "file=@$FILE_PATH" \
        -F "endpointId=$ENDPOINT" \
        -F "Name=$STACK_NAME" --insecure)


      # Imprimir a resposta da requisição 
      echo "Resposta da solicitação POST: $response"

      # Extrair o valor do campo "Id" da nova stack usando jq
      id=$(echo "$response" | jq -r '.Id')

      # Imprimir o valor do Id
      echo "Nova Stack criada. Id: $id"
    fi 
  fi
done

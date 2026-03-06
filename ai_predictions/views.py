from rest_framework.response import Response
from rest_framework.views import APIView


class BestDaysView(APIView):
    """
    GET /ai/best-days
    Retorna os melhores dias para trabalhar com base no histórico
    de transações do usuário.
    (placeholder — implementar modelo de IA futuramente)
    """

    def get(self, request):
        # TODO: substituir por predição real
        return Response(
            {
                "detail": "Endpoint disponível. Predição IA ainda não implementada.",
                "endpoint": "/ai/best-days",
                "data": [],
            }
        )


class SuggestionsView(APIView):
    """
    GET /ai/suggestions
    Retorna sugestões personalizadas de economia / ganhos
    com base no perfil e histórico do usuário.
    (placeholder — implementar modelo de IA futuramente)
    """

    def get(self, request):
        # TODO: substituir por predição real
        return Response(
            {
                "detail": "Endpoint disponível. Predição IA ainda não implementada.",
                "endpoint": "/ai/suggestions",
                "data": [],
            }
        )


class BestHoursView(APIView):
    """
    GET /ai/best-hours
    Retorna os melhores horários para trabalhar com base no
    histórico de transações do usuário.
    (placeholder — implementar modelo de IA futuramente)
    """

    def get(self, request):
        # TODO: substituir por predição real
        return Response(
            {
                "detail": "Endpoint disponível. Predição IA ainda não implementada.",
                "endpoint": "/ai/best-hours",
                "data": [],
            }
        )

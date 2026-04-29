"use client"

import { useEffect, useState } from "react"
import {
  BarChart3, Users, Building2, Hammer, Clock, Activity,
  FolderTree, Users2, Briefcase, UserCog, LogIn, LogOut,
  UserPlus, Calendar, CheckCircle, XCircle, AlertCircle,
  MousePointer, Search, Layout
} from "lucide-react"
import { getDashboardData, type DashboardData } from "@/lib/dashboard-service"

interface StatCard {
  title: string
  value: number | string
  icon: React.ElementType
  change?: string
  changeType?: 'positive' | 'negative'
  color?: string
}

export default function AdminDashboard() {
  const [data, setData] = useState<DashboardData | null>(null)
  const [isLoading, setIsLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)
  const [activeTab, setActiveTab] = useState<'resumo' | 'usuarios' | 'agendamentos' | 'logs'>('resumo')

  useEffect(() => {
    loadDashboardData()
  }, [])

  const loadDashboardData = async () => {
    try {
      setIsLoading(true)
      const dashboardData = await getDashboardData()
      setData(dashboardData)
      setError(null)
    } catch (err) {
      console.error('Erro ao carregar dashboard:', err)
      setError('Não foi possível carregar os dados do dashboard')
    } finally {
      setIsLoading(false)
    }
  }

  if (isLoading) {
    return (
      <div className="min-h-[calc(100vh-10rem)] flex items-center justify-center">
        <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-gray-900 dark:border-gray-100"></div>
      </div>
    )
  }

  if (error) {
    return (
      <div className="min-h-[calc(100vh-10rem)] flex items-center justify-center">
        <div className="bg-red-50 dark:bg-red-900/20 border border-red-200 dark:border-red-800 rounded-lg p-6 text-center">
          <p className="text-red-600 dark:text-red-400 mb-4">{error}</p>
          <button
            onClick={loadDashboardData}
            className="px-4 py-2 bg-red-600 hover:bg-red-700 text-white rounded-lg transition-colors"
          >
            Tentar novamente
          </button>
        </div>
      </div>
    )
  }

  if (!data) {
    return null
  }

  // Cards baseados nos dados da API
  const stats: StatCard[] = [
    {
      title: "Empresas",
      value: data.quantidadeUsuarios.empresas.total,
      icon: Building2,
      color: "bg-blue-100 dark:bg-blue-900/20 text-blue-600 dark:text-blue-400"
    },
    {
      title: "Clientes",
      value: data.quantidadeUsuarios.clientes.total,
      icon: Users,
      color: "bg-green-100 dark:bg-green-900/20 text-green-600 dark:text-green-400"
    },
    {
      title: "Prestadores",
      value: data.quantidadeUsuarios.prestadores.total,
      icon: Hammer,
      color: "bg-purple-100 dark:bg-purple-900/20 text-purple-600 dark:text-purple-400"
    },
    {
      title: "Agendamentos",
      value: data.agendamentosStatus.total,
      icon: Calendar,
      color: "bg-orange-100 dark:bg-orange-900/20 text-orange-600 dark:text-orange-400"
    },
    {
      title: "Agen. p/ Estabelecimento",
      value: data.agendamentosPorTipo.viaEstabelecimento,
      icon: Building2,
      color: "bg-indigo-100 dark:bg-indigo-900/20 text-indigo-600 dark:text-indigo-400"
    },
    {
      title: "Agen. p/ Prestador",
      value: data.agendamentosPorTipo.diretoPrestador,
      icon: UserCog,
      color: "bg-yellow-100 dark:bg-yellow-900/20 text-yellow-600 dark:text-yellow-400"
    },
    {
      title: "Iniciados por Pesquisa",
      value: data.agendamentosIniciadosPorBotao.pesquisa,
      icon: Search,
      color: "bg-cyan-100 dark:bg-cyan-900/20 text-cyan-600 dark:text-cyan-400"
    },
    {
      title: "Iniciados Botão Central",
      value: data.agendamentosIniciadosPorBotao.botaoCentral,
      icon: Layout,
      color: "bg-pink-100 dark:bg-pink-900/20 text-pink-600 dark:text-pink-400"
    },
    {
      title: "Iniciados Botão Tela",
      value: data.agendamentosIniciadosPorBotao.botaoTela,
      icon: MousePointer,
      color: "bg-emerald-100 dark:bg-emerald-900/20 text-emerald-600 dark:text-emerald-400"
    },
  ]

  return (
    <div className="space-y-6">
      {/* Header com data de atualização */}
      <div className="flex items-center justify-between">
        <h1 className="text-2xl font-bold text-gray-900 dark:text-gray-100">
          Dashboard Administrativo
        </h1>
        <button
          onClick={loadDashboardData}
          className="px-3 py-1 text-sm bg-gray-100 dark:bg-gray-800 hover:bg-gray-200 dark:hover:bg-gray-700 text-gray-700 dark:text-gray-300 rounded-lg transition-colors flex items-center gap-2"
        >
          <svg
            className="w-4 h-4"
            fill="none"
            stroke="currentColor"
            viewBox="0 0 24 24"
          >
            <path
              strokeLinecap="round"
              strokeLinejoin="round"
              strokeWidth={2}
              d="M4 4v5h.582m15.356 2A8.001 8.001 0 004.582 9m0 0H9m11 11v-5h-.581m0 0a8.003 8.003 0 01-15.357-2m15.357 2H15"
            />
          </svg>
          Atualizar
        </button>
      </div>

      {/* Tabs */}
      <div className="border-b border-gray-200 dark:border-gray-800">
        <nav className="flex gap-4">
          <button
            onClick={() => setActiveTab('resumo')}
            className={`px-4 py-2 text-sm font-medium transition-colors ${activeTab === 'resumo'
              ? 'text-blue-600 dark:text-blue-400 border-b-2 border-blue-600 dark:border-blue-400'
              : 'text-gray-500 dark:text-gray-400 hover:text-gray-700 dark:hover:text-gray-300'
              }`}
          >
            Resumo Geral
          </button>
          <button
            onClick={() => setActiveTab('usuarios')}
            className={`px-4 py-2 text-sm font-medium transition-colors ${activeTab === 'usuarios'
              ? 'text-blue-600 dark:text-blue-400 border-b-2 border-blue-600 dark:border-blue-400'
              : 'text-gray-500 dark:text-gray-400 hover:text-gray-700 dark:hover:text-gray-300'
              }`}
          >
            Usuários
          </button>
          <button
            onClick={() => setActiveTab('agendamentos')}
            className={`px-4 py-2 text-sm font-medium transition-colors ${activeTab === 'agendamentos'
              ? 'text-blue-600 dark:text-blue-400 border-b-2 border-blue-600 dark:border-blue-400'
              : 'text-gray-500 dark:text-gray-400 hover:text-gray-700 dark:hover:text-gray-300'
              }`}
          >
            Agendamentos
          </button>
          <button
            onClick={() => setActiveTab('logs')}
            className={`px-4 py-2 text-sm font-medium transition-colors ${activeTab === 'logs'
              ? 'text-blue-600 dark:text-blue-400 border-b-2 border-blue-600 dark:border-blue-400'
              : 'text-gray-500 dark:text-gray-400 hover:text-gray-700 dark:hover:text-gray-300'
              }`}
          >
            Logs e Atividades
          </button>
        </nav>
      </div>

      {/* Conteúdo das Tabs */}
      <div className="space-y-6">
        {activeTab === 'resumo' && (
          <>
            {/* Stats Grid */}
            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-4">
              {stats.map((stat, index) => (
                <div
                  key={index}
                  className="bg-white dark:bg-gray-900 rounded-lg border border-gray-200 dark:border-gray-800 p-5 hover:shadow-md transition-shadow"
                >
                  <div className="flex items-start justify-between">
                    <div className={`p-2.5 rounded-lg ${stat.color}`}>
                      <stat.icon size={22} />
                    </div>
                    <span className="text-xs font-medium text-gray-500 dark:text-gray-400">
                      {stat.title}
                    </span>
                  </div>
                  <div className="mt-3">
                    <h3 className="text-2xl font-bold text-gray-900 dark:text-gray-100">
                      {typeof stat.value === 'number' ? stat.value.toLocaleString() : stat.value}
                    </h3>
                  </div>
                </div>
              ))}
            </div>

            {/* Resumo de Status */}
            <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">

              {/* Status de Usuários */}
              <div className="bg-white dark:bg-gray-900 rounded-lg border border-gray-200 dark:border-gray-800 p-6">
                <h2 className="text-lg font-semibold text-gray-900 dark:text-gray-100 mb-4">
                  Clientes
                </h2>
                <div className="space-y-4">
                  <div>
                    <h3 className="text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">Status</h3>
                    {Object.entries(data.quantidadeUsuarios.clientes.porStatus).map(([status, count]) => (
                      <div key={status} className="flex justify-between items-center">
                        <span className="text-sm text-gray-600 dark:text-gray-400">{status}</span>
                        <span className="text-lg font-semibold text-gray-900 dark:text-gray-100">{count}</span>
                      </div>
                    ))}
                  </div>
                </div>
                <br />
                <div className="space-y-4">
                  <div>
                    <h3 className="text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">Tipo de Login</h3>
                    {Object.entries(data.quantidadeUsuarios.clientes.porLogin).map(([status, count]) => (
                      <div key={status} className="flex justify-between items-center">
                        <span className="text-sm text-gray-600 dark:text-gray-400">{status}</span>
                        <span className="text-lg font-semibold text-gray-900 dark:text-gray-100">{count}</span>
                      </div>
                    ))}
                  </div>
                </div>
              </div>

              <div className="bg-white dark:bg-gray-900 rounded-lg border border-gray-200 dark:border-gray-800 p-6">
                <h2 className="text-lg font-semibold text-gray-900 dark:text-gray-100 mb-4">
                  Prestadores
                </h2>
                <div className="space-y-4">
                  <div>
                    <h3 className="text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">Status</h3>
                    {Object.entries(data.quantidadeUsuarios.prestadores.porStatus).map(([status, count]) => (
                      <div key={status} className="flex justify-between items-center">
                        <span className="text-sm text-gray-600 dark:text-gray-400">{status}</span>
                        <span className="text-lg font-semibold text-gray-900 dark:text-gray-100">{count}</span>
                      </div>
                    ))}
                  </div>
                </div>
                <br />
                <div className="space-y-4">
                  <div>
                    <h3 className="text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">Tipo de Login</h3>
                    {Object.entries(data.quantidadeUsuarios.prestadores.porLogin).map(([status, count]) => (
                      <div key={status} className="flex justify-between items-center">
                        <span className="text-sm text-gray-600 dark:text-gray-400">{status}</span>
                        <span className="text-lg font-semibold text-gray-900 dark:text-gray-100">{count}</span>
                      </div>
                    ))}
                  </div>
                </div>
              </div>

              {/* Status de Empresas */}
              <div className="bg-white dark:bg-gray-900 rounded-lg border border-gray-200 dark:border-gray-800 p-6">
                <h2 className="text-lg font-semibold text-gray-900 dark:text-gray-100 mb-4">
                  Empresas
                </h2>
                <div className="space-y-4">
                  <div>
                    <h3 className="text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">Status</h3>
                    {Object.entries(data.quantidadeUsuarios.empresas.porStatus).map(([status, count]) => (
                      <div key={status} className="flex justify-between items-center">
                        <span className="text-sm text-gray-600 dark:text-gray-400">{status}</span>
                        <span className="text-lg font-semibold text-gray-900 dark:text-gray-100">{count}</span>
                      </div>
                    ))}
                  </div>
                </div>
                <br />
                <div className="space-y-4">
                  <div>
                    <h3 className="text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">Tipo de Login</h3>
                    {Object.entries(data.quantidadeUsuarios.empresas.porLogin).map(([status, count]) => (
                      <div key={status} className="flex justify-between items-center">
                        <span className="text-sm text-gray-600 dark:text-gray-400">{status}</span>
                        <span className="text-lg font-semibold text-gray-900 dark:text-gray-100">{count}</span>
                      </div>
                    ))}
                  </div>
                </div>
              </div>
            </div>
          </>
        )}

        {activeTab === 'usuarios' && (
          <>
            {/* Últimos Logins */}
            <div className="bg-white dark:bg-gray-900 rounded-lg border border-gray-200 dark:border-gray-800 p-6">
              <h2 className="text-lg font-semibold text-gray-900 dark:text-gray-100 mb-4 flex items-center gap-2">
                <LogIn size={20} />
                Últimos Logins/Acessos
              </h2>
              <div className="overflow-x-auto">
                <table className="w-full">
                  <thead className="border-b border-gray-200 dark:border-gray-800">
                    <tr className="text-left text-sm text-gray-500 dark:text-gray-400">
                      <th className="pb-2">Nome</th>
                      <th className="pb-2">E-mail</th>
                      <th className="pb-2">Tipo</th>
                      <th className="pb-2">Último Login</th>
                      <th className="pb-2">Inatividade</th>
                      <th className="pb-2">Status</th>
                    </tr>
                  </thead>
                  <tbody>
                    {data.ultimosLogins.map((login, idx) => (
                      <tr key={idx} className="border-b border-gray-100 dark:border-gray-800">
                        <td className="py-3 text-sm text-gray-600 dark:text-gray-400">{login.nome}</td>
                        <td className="py-3 text-sm text-gray-600 dark:text-gray-400">{login.email}</td>
                        <td className="py-3 text-sm text-gray-600 dark:text-gray-400">{login.tipo}</td>
                        <td className="py-3 text-sm text-gray-600 dark:text-gray-400">
                          {login.ultimoLogin.replace('T', ' ').substring(0, 19)}
                        </td>
                        <td className="py-3 text-sm text-gray-600 dark:text-gray-400">{login.inativo}</td>
                        <td className="py-3 text-sm">
                          <span className={`px-2 py-1 rounded-full text-xs ${login.status === 'ATIVO' || login.status === 'ATIVA'
                            ? 'bg-green-100 dark:bg-green-900/20 text-green-700 dark:text-green-400'
                            : 'bg-red-100 dark:bg-red-900/20 text-red-700 dark:text-red-400'
                            }`}>
                            {login.status}
                          </span>
                        </td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            </div>

            {/* Últimos Cadastros */}
            <div className="bg-white dark:bg-gray-900 rounded-lg border border-gray-200 dark:border-gray-800 p-6">
              <h2 className="text-lg font-semibold text-gray-900 dark:text-gray-100 mb-4 flex items-center gap-2">
                <UserPlus size={20} />
                Últimos Cadastros
              </h2>
              <div className="overflow-x-auto">
                <table className="w-full">
                  <thead className="border-b border-gray-200 dark:border-gray-800">
                    <tr className="text-left text-sm text-gray-500 dark:text-gray-400">
                      <th className="pb-2">Nome</th>
                      <th className="pb-2">E-mail</th>
                      <th className="pb-2">Tipo</th>
                      <th className="pb-2">Data Cadastro</th>
                      <th className="pb-2">Status</th>
                    </tr>
                  </thead>
                  <tbody>
                    {data.ultimosCadastros.map((cadastro, idx) => (
                      <tr key={idx} className="border-b border-gray-100 dark:border-gray-800">
                        <td className="py-3 text-sm text-gray-600 dark:text-gray-400">{cadastro.nome}</td>
                        <td className="py-3 text-sm text-gray-600 dark:text-gray-400">{cadastro.email}</td>
                        <td className="py-3 text-sm text-gray-600 dark:text-gray-400">{cadastro.tipo}</td>
                        <td className="py-3 text-sm text-gray-600 dark:text-gray-400">
                          {new Date(cadastro.dataCriacao).toLocaleString()}
                        </td>
                        <td className="py-3 text-sm">
                          <span className={`px-2 py-1 rounded-full text-xs ${cadastro.status === 'ATIVO' || cadastro.status === 'ATIVA'
                            ? 'bg-green-100 dark:bg-green-900/20 text-green-700 dark:text-green-400'
                            : 'bg-red-100 dark:bg-red-900/20 text-red-700 dark:text-red-400'
                            }`}>
                            {cadastro.status}
                          </span>
                        </td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            </div>

            {/* Estabelecimentos por Empresa */}
            <div className="bg-white dark:bg-gray-900 rounded-lg border border-gray-200 dark:border-gray-800 p-6">
              <h2 className="text-lg font-semibold text-gray-900 dark:text-gray-100 mb-4 flex items-center gap-2">
                <Building2 size={20} />
                Estabelecimentos por Empresa
              </h2>
              <div className="space-y-4">
                {data.estabelecimentosPorEmpresa.map((empresa, idx) => (
                  <div key={idx} className="border-b border-gray-100 dark:border-gray-800 pb-3 last:border-0">
                    <div className="flex justify-between items-center mb-2">
                      <h3 className="font-medium text-gray-900 dark:text-gray-100">{empresa.empresaNome}</h3>
                      <span className="text-sm text-gray-500 dark:text-gray-400">
                        {empresa.quantidadeEstabelecimentos} estabelecimentos
                      </span>
                    </div>
                    <p className="text-sm text-gray-600 dark:text-gray-400">
                      Total de prestadores: {empresa.quantidadePrestadores}
                    </p>
                  </div>
                ))}
              </div>
            </div>
          </>
        )}

        {activeTab === 'agendamentos' && (
          <>
            {/* Status dos Agendamentos */}
            <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
              <div className="bg-white dark:bg-gray-900 rounded-lg border border-gray-200 dark:border-gray-800 p-6">
                <h2 className="text-lg font-semibold text-gray-900 dark:text-gray-100 mb-4">
                  Status dos Agendamentos
                </h2>
                <div className="space-y-3">
                  {Object.entries(data.agendamentosStatus.porStatus).map(([status, count]) => (
                    <div key={status} className="flex justify-between items-center">
                      <span className="text-sm text-gray-600 dark:text-gray-400">{status}</span>
                      <span className="text-lg font-semibold text-gray-900 dark:text-gray-100">{count}</span>
                    </div>
                  ))}
                  <div className="pt-3 border-t border-gray-200 dark:border-gray-800 flex justify-between items-center font-semibold">
                    <span className="text-gray-900 dark:text-gray-100">Total</span>
                    <span className="text-gray-900 dark:text-gray-100">{data.agendamentosStatus.total}</span>
                  </div>
                </div>
              </div>

              <div className="bg-white dark:bg-gray-900 rounded-lg border border-gray-200 dark:border-gray-800 p-6">
                <h2 className="text-lg font-semibold text-gray-900 dark:text-gray-100 mb-4">
                  Finalização de Agendamentos
                </h2>
                <div className="space-y-4">
                  <div className="flex justify-between items-center">
                    <span className="text-sm text-gray-600 dark:text-gray-400">Total Iniciados</span>
                    <span className="text-lg font-semibold text-gray-900 dark:text-gray-100">
                      {data.agendamentosFinalizacao.total.iniciados}
                    </span>
                  </div>
                  <div className="flex justify-between items-center">
                    <span className="text-sm text-gray-600 dark:text-gray-400">Finalizados</span>
                    <span className="text-lg font-semibold text-green-600 dark:text-green-400">
                      {data.agendamentosFinalizacao.total.finalizados}
                    </span>
                  </div>
                  <div className="flex justify-between items-center">
                    <span className="text-sm text-gray-600 dark:text-gray-400">Não Finalizados</span>
                    <span className="text-lg font-semibold text-red-600 dark:text-red-400">
                      {data.agendamentosFinalizacao.total.naoFinalizados}
                    </span>
                  </div>
                  <div className="flex justify-between items-center pt-3 border-t border-gray-200 dark:border-gray-800">
                    <span className="text-sm font-medium text-gray-900 dark:text-gray-100">Taxa de Finalização</span>
                    <span className="text-lg font-bold text-blue-600 dark:text-blue-400">
                      {data.agendamentosFinalizacao.total.taxaFinalizacao}
                    </span>
                  </div>
                </div>
              </div>
            </div>

            {/* Detalhamento por Tipo de Início */}
            <div className="bg-white dark:bg-gray-900 rounded-lg border border-gray-200 dark:border-gray-800 p-6">
              <h2 className="text-lg font-semibold text-gray-900 dark:text-gray-100 mb-4">
                Agendamentos por Tipo de Início
              </h2>
              <div className="space-y-6">
                {Object.entries(data.agendamentosFinalizacao).map(([tipo, dados]) => {
                  if (tipo === 'total') return null
                  return (
                    <div key={tipo} className="border-b border-gray-100 dark:border-gray-800 pb-4 last:border-0">
                      <h3 className="font-medium text-gray-900 dark:text-gray-100 mb-3 capitalize">
                        {tipo === 'pesquisa' ? 'Via Pesquisa' : tipo === 'botaoCentral' ? 'Botão Central' : 'Botão na Tela'}
                      </h3>
                      <div className="grid grid-cols-3 gap-4 text-center">
                        <div>
                          <p className="text-xs text-gray-500 dark:text-gray-400">Iniciados</p>
                          <p className="text-lg font-semibold text-gray-900 dark:text-gray-100">{dados.iniciados}</p>
                        </div>
                        <div>
                          <p className="text-xs text-gray-500 dark:text-gray-400">Finalizados</p>
                          <p className="text-lg font-semibold text-green-600 dark:text-green-400">{dados.finalizados}</p>
                        </div>
                        <div>
                          <p className="text-xs text-gray-500 dark:text-gray-400">Taxa</p>
                          <p className="text-lg font-semibold text-blue-600 dark:text-blue-400">{dados.taxaFinalizacao}</p>
                        </div>
                      </div>
                    </div>
                  )
                })}
              </div>
            </div>
          </>
        )}

        {activeTab === 'logs' && (
          <>
            {/* Últimas Entradas/Saídas */}
            <div className="bg-white dark:bg-gray-900 rounded-lg border border-gray-200 dark:border-gray-800 p-6">
              <h2 className="text-lg font-semibold text-gray-900 dark:text-gray-100 mb-4 flex items-center gap-2">
                <LogIn size={20} />
                <LogOut size={20} />
                Últimas Entradas e Saídas
              </h2>
              <div className="overflow-x-auto">
                <table className="w-full">
                  <thead className="border-b border-gray-200 dark:border-gray-800">
                    <tr className="text-left text-sm text-gray-500 dark:text-gray-400">
                      <th className="pb-2">Ação</th>
                      <th className="pb-2">Usuário/Empresa</th>
                      <th className="pb-2">E-mail</th>
                      <th className="pb-2">Data/Hora</th>
                      <th className="pb-2">Detalhe</th>
                    </tr>
                  </thead>
                  <tbody>
                    {data.ultimasEntradasSaidas.map((log, idx) => (
                      <tr key={idx} className="border-b border-gray-100 dark:border-gray-800">
                        <td className="py-3 text-sm">
                          <span className={`inline-flex items-center gap-1 px-2 py-1 rounded-full text-xs ${log.acao === 'LOGIN' || log.acao === 'LOGIN_GOOGLE'
                            ? 'bg-green-100 dark:bg-green-900/20 text-green-700 dark:text-green-400'
                            : log.acao === 'ENTRADA_DIRETA' ? 'bg-blue-100 dark:bg-blue-900/20 text-blue-700 dark:text-blue-400' : 'bg-red-100 dark:bg-red-900/20 text-red-700 dark:text-red-400'
                            }`}>
                            {log.acao === 'LOGIN' || log.acao === 'LOGIN_GOOGLE' ? <LogIn size={12} /> : <LogOut size={12} />}
                            {log.acao}
                          </span>
                        </td>
                        <td className="py-3 text-sm text-gray-600 dark:text-gray-400">{log.nome}</td>
                        <td className="py-3 text-sm text-gray-600 dark:text-gray-400">{log.email}</td>
                        <td className="py-3 text-sm text-gray-600 dark:text-gray-400">
                          {log.data.replace('T', ' ').substring(0, 19)}
                        </td>
                        <td className="py-3 text-sm text-gray-500 dark:text-gray-400">{log.detalhe}</td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            </div>

          </>
        )}
      </div>
    </div>
  )
}
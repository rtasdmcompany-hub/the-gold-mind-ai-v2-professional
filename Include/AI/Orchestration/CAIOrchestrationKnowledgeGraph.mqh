//+------------------------------------------------------------------+
//|                            CAIOrchestrationKnowledgeGraph.mqh |
//|                        THE GOLD MIND AI PROFESSIONAL            |
//|     Expanded knowledge graph — complements Memory skeleton      |
//+------------------------------------------------------------------+
#ifndef GM_CAI_ORCHESTRATION_KNOWLEDGE_GRAPH_MQH
#define GM_CAI_ORCHESTRATION_KNOWLEDGE_GRAPH_MQH
#property copyright "Copyright 2026, RTAS Group of Companies"
#property link      "https://rtas.group"

#include "SGmOrchestrationResult.mqh"
#include "../Intelligence/SGmIntelligenceResult.mqh"
#include "../RiskIntelligence/SGmRiskIntelligenceResult.mqh"
#include "../Forecasting/SGmForecastResult.mqh"
#include "../Memory/SGmMemoryLearningResult.mqh"
#include "../Assistant/SGmAssistantResult.mqh"

struct SGmOrchGraphNode
  {
   string id;
   string kind;
   string label;
   bool   active;
   void Reset(void) { id = kind = label = ""; active = false; }
  };

struct SGmOrchGraphEdge
  {
   string from_id;
   string to_id;
   string relation;
   bool   active;
   void Reset(void) { from_id = to_id = relation = ""; active = false; }
  };

class CGmAIOrchestrationKnowledgeGraph
  {
private:
   SGmOrchGraphNode m_nodes[GM_ORCH_GRAPH_NODES];
   SGmOrchGraphEdge m_edges[GM_ORCH_GRAPH_EDGES];
   int              m_n_nodes;
   int              m_n_edges;

   void AddNode(const string id, const string kind, const string label)
     {
      if(m_n_nodes >= GM_ORCH_GRAPH_NODES) return;
      m_nodes[m_n_nodes].id = id;
      m_nodes[m_n_nodes].kind = kind;
      m_nodes[m_n_nodes].label = label;
      m_nodes[m_n_nodes].active = true;
      m_n_nodes++;
     }

   void AddEdge(const string from_id, const string to_id, const string rel)
     {
      if(m_n_edges >= GM_ORCH_GRAPH_EDGES) return;
      m_edges[m_n_edges].from_id = from_id;
      m_edges[m_n_edges].to_id = to_id;
      m_edges[m_n_edges].relation = rel;
      m_edges[m_n_edges].active = true;
      m_n_edges++;
     }

public:
                     CGmAIOrchestrationKnowledgeGraph(void) : m_n_nodes(0), m_n_edges(0) {}

   void Reset(void)
     {
      m_n_nodes = m_n_edges = 0;
      for(int i = 0; i < GM_ORCH_GRAPH_NODES; i++) m_nodes[i].Reset();
      for(int j = 0; j < GM_ORCH_GRAPH_EDGES; j++) m_edges[j].Reset();
     }

   void Rebuild(const SGmIntelligenceResult &intel,
                const SGmRiskIntelligenceResult &risk,
                const SGmForecastResult &fcst,
                const SGmMemoryLearningResult &mem,
                const SGmAssistantResult &sup,
                SGmOrchestrationResult &r)
     {
      Reset();
      AddNode("mkt", "Market Events", intel.valid ? intel.market_score_condition : "Market");
      AddNode("risk", "Risk Events", risk.valid ? GmRiskLevelName(risk.risk_level) : "Risk");
      AddNode("sess", "Strategy Sessions", "H4 Session Observation");
      AddNode("fcst", "Forecast Results", fcst.valid ? GmFcstOutlookName(fcst.outlook) : "Forecast");
      AddNode("learn", "Learning Outcomes", mem.valid ? "Adaptive Learning" : "Learning");
      AddNode("sys", "System Events", sup.valid ? sup.supervisor_status : "System");

      AddEdge("mkt", "fcst", "Similar Pattern");
      AddEdge("fcst", "risk", "Risk Connection");
      AddEdge("risk", "sess", "Previous Outcome");
      AddEdge("learn", "mkt", "Learning Connection");
      AddEdge("sys", "risk", "Performance Connection");
      AddEdge("sess", "learn", "Performance Connection");
      if(fcst.valid && fcst.transition_detected)
         AddEdge("mkt", "sys", "Similar Pattern");
      if(risk.valid && risk.alert_count > 0)
         AddEdge("risk", "sys", "Risk Connection");

      r.graph_nodes = m_n_nodes;
      r.graph_edges = m_n_edges;
      r.knowledge_network = StringFormat("Nodes=%d Edges=%d | Market/Risk/Session/Forecast/Learning/System",
                                         m_n_nodes, m_n_edges);
      r.knowledge_links = "";
      const int show = MathMin(m_n_edges, 6);
      for(int e = 0; e < show; e++)
        {
         if(e > 0) r.knowledge_links += " | ";
         r.knowledge_links += StringFormat("%s-%s(%s)",
                                           m_edges[e].from_id, m_edges[e].to_id, m_edges[e].relation);
        }
     }
  };

#endif // GM_CAI_ORCHESTRATION_KNOWLEDGE_GRAPH_MQH
//+------------------------------------------------------------------+

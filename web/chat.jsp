<%@ page import="java.sql.*, java.util.*" %>
<%@ page import="com.globalcommunication.utils.SentimentAnalyzer" %>
<%@ page import="com.globalcommunication.utils.SentimentAnalyzer.SentimentResult" %>
<%@ page session="true" %>
<%@ page pageEncoding="UTF-8" contentType="text/html; charset=UTF-8" %>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Group Chat | Real-time Conversation</title>
    <link rel="stylesheet" href="assets/css/global.css">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.0.0/css/all.min.css">
    <style>
        .chat-container {
            height: 70vh;
            background: white;
            border-radius: 0.5rem;
            display: flex;
            flex-direction: column;
            box-shadow: 0 4px 6px rgba(0, 0, 0, 0.1);
        }

        .chat-header {
            padding: 1rem;
            border-bottom: 1px solid #e5e7eb;
            display: flex;
            justify-content: space-between;
            align-items: center;
        }

        .chat-messages {
            flex-grow: 1;
            overflow-y: auto;
            padding: 1rem;
            background: #f9fafb;
        }

        .message {
            margin: 1rem 0;
            padding: 0.75rem;
            background: white;
            border-radius: 0.5rem;
            box-shadow: 0 1px 2px rgba(0, 0, 0, 0.05);
        }

        .message-header {
            display: flex;
            justify-content: space-between;
            margin-bottom: 0.5rem;
        }

        .message-sender {
            color: #8b5cf6;
            font-weight: 600;
        }

        .message-time {
            color: #6b7280;
            font-size: 0.875rem;
        }

        .message-content {
            color: #374151;
            line-height: 1.5;
        }

        .chat-input {
            padding: 1rem;
            border-top: 1px solid #e5e7eb;
            background: white;
        }

        .input-form {
            display: flex;
            gap: 1rem;
        }

        .message-textarea {
            flex-grow: 1;
            padding: 0.75rem;
            border: 1px solid #d1d5db;
            border-radius: 0.375rem;
            resize: none;
            height: 60px;
        }

        .online-indicator {
            display: inline-flex;
            align-items: center;
            gap: 0.5rem;
            color: #059669;
            font-size: 0.875rem;
        }

        .status-dot {
            height: 8px;
            width: 8px;
            background-color: #059669;
            border-radius: 50%;
        }
        
        .sentiment-indicator {
            margin-left: 0.5rem;
            font-size: 1.2rem;
        }
        
        .sentiment-summary {
            display: flex;
            align-items: center;
            gap: 1rem;
            padding: 0.5rem 1rem;
            background: #f3f4f6;
            border-radius: 0.375rem;
            margin-bottom: 1rem;
            font-size: 0.875rem;
            color: #4b5563;
        }
        
        .sentiment-badge {
            display: inline-flex;
            align-items: center;
            padding: 0.25rem 0.5rem;
            border-radius: 9999px;
            font-size: 0.75rem;
            font-weight: 500;
        }
        
        .sentiment-positive {
            background-color: #d1fae5;
            color: #065f46;
        }
        
        .sentiment-negative {
            background-color: #fee2e2;
            color: #991b1b;
        }
        
        .sentiment-neutral {
            background-color: #e5e7eb;
            color: #374151;
        }
    </style>
</head>
<body>
    <div class="page-container">
        <form action="group_chat.jsp" method="get" style="padding: 1rem;">
            <button type="submit" class="primary-button" style="max-width: 200px;">
                <i class="fas fa-arrow-left"></i> Back to Groups
            </button>
        </form>

        <div class="form-container" style="margin-top: -2rem;">
            <div class="form-card" style="max-width: 800px;">
                <div class="chat-container">
                    <div class="chat-header">
                        <div>
                            <h2 class="form-title" style="margin-bottom: 0.5rem;">Group Chat #<%= request.getParameter("group_id") %></h2>
                            <div class="online-indicator">
                                <span class="status-dot"></span>
                                <span>Chat Active</span>
                            </div>
                        </div>
                        <div style="color: #6b7280; display: flex; align-items: center; gap: 1rem;">
                            <a href="sentiment_analytics.jsp?group_id=<%= request.getParameter("group_id") %>" class="primary-button" style="font-size: 0.875rem; padding: 0.5rem 0.75rem;">
                                <i class="fas fa-chart-line"></i> Sentiment Analytics
                            </a>
                            <div>
                                <i class="fas fa-users"></i> Active Members
                            </div>
                        </div>
                    </div>

                    <div class="chat-messages" id="chatMessages">
                        <%
                            // Sentiment analysis statistics
                            int positiveCount = 0;
                            int neutralCount = 0;
                            int negativeCount = 0;
                            
                            try {
                                Class.forName("org.postgresql.Driver");
                                Connection conn = DriverManager.getConnection("jdbc:postgresql://localhost:5432/global", "postgres", "say my name");

                                String chatQuery = "SELECT sender, message, timestamp FROM group_messages WHERE group_id = ? ORDER BY timestamp";
                                PreparedStatement chatStmt = conn.prepareStatement(chatQuery);
                                chatStmt.setInt(1, Integer.parseInt(request.getParameter("group_id")));
                                ResultSet chatRs = chatStmt.executeQuery();
                                
                                // Display sentiment summary at the top
                        %>
                                <div class="sentiment-summary">
                                    <h3 style="margin: 0;">Conversation Sentiment Analysis</h3>
                                    <div id="sentimentSummary">Analyzing messages...</div>
                                </div>
                        <%
                                while (chatRs.next()) {
                                    String sender = chatRs.getString("sender");
                                    String message = chatRs.getString("message");
                                    Timestamp timestamp = chatRs.getTimestamp("timestamp");
                                    
                                    // Analyze sentiment
                                    SentimentResult sentiment = SentimentAnalyzer.analyzeSentiment(message);
                                    String sentimentCategory = sentiment.getCategory();
                                    String sentimentEmoji = SentimentAnalyzer.getSentimentEmoji(sentimentCategory);
                                    
                                    // Update sentiment counts
                                    if ("POSITIVE".equals(sentimentCategory)) {
                                        positiveCount++;
                                    } else if ("NEGATIVE".equals(sentimentCategory)) {
                                        negativeCount++;
                                    } else {
                                        neutralCount++;
                                    }
                                    
                                    // Determine badge class based on sentiment
                                    String badgeClass = "";
                                    if ("POSITIVE".equals(sentimentCategory)) {
                                        badgeClass = "sentiment-positive";
                                    } else if ("NEGATIVE".equals(sentimentCategory)) {
                                        badgeClass = "sentiment-negative";
                                    } else {
                                        badgeClass = "sentiment-neutral";
                                    }
                        %>
                                    <div class="message">
                                        <div class="message-header">
                                            <span class="message-sender">
                                                <i class="fas fa-user-circle"></i> <%= sender %>
                                                <span class="sentiment-badge <%= badgeClass %>">
                                                    <%= sentimentEmoji %> <%= sentimentCategory.toLowerCase() %>
                                                </span>
                                            </span>
                                            <span class="message-time">
                                                <i class="fas fa-clock"></i> <%= timestamp %>
                                            </span>
                                        </div>
                                        <div class="message-content"><%= message %></div>
                                    </div>
                        <%
                                }
                                chatStmt.close();
                                conn.close();
                            } catch (Exception e) {
                                out.println("<p class='error-message'><i class='fas fa-exclamation-circle'></i> Error: " + e.getMessage() + "</p>");
                            }
                        %>
                    </div>

                    <div class="chat-input">
                        <form action="chat.jsp" method="post" class="input-form">
                            <input type="hidden" name="group_id" value="<%= request.getParameter("group_id") %>">
                            <!-- Hidden fields for sentiment counts -->
                            <input type="hidden" id="positive-count" value="<%= positiveCount %>">
                            <input type="hidden" id="neutral-count" value="<%= neutralCount %>">
                            <input type="hidden" id="negative-count" value="<%= negativeCount %>">
                            <textarea 
                                name="messageContent" 
                                class="message-textarea" 
                                placeholder="Type your message here..."
                                required
                            ></textarea>
                            <button type="submit" name="send_message" class="primary-button" style="width: auto; padding: 0 1.5rem;">
                                <i class="fas fa-paper-plane"></i>
                            </button>
                        </form>
                        <% 
                            String messageStatus = "";
                            if (request.getParameter("send_message") != null) {
                                String messageContent = request.getParameter("messageContent");
                                String currentUser = (String) session.getAttribute("username");
                                
                                // Analyze sentiment of new message
                                SentimentResult sentimentResult = SentimentAnalyzer.analyzeSentiment(messageContent);
                                String sentimentCategory = sentimentResult.getCategory();
                                double sentimentScore = sentimentResult.getScore();
                                
                                try {
                                    Class.forName("org.postgresql.Driver");
                                    Connection conn = DriverManager.getConnection("jdbc:postgresql://localhost:5432/global", "postgres", "say my name");

                                    // Updated query to include sentiment data
                                    String insertMessageQuery = "INSERT INTO group_messages (group_id, sender, message, sentiment, sentiment_score) VALUES (?, ?, ?, ?, ?)";
                                    PreparedStatement insertStmt = conn.prepareStatement(insertMessageQuery);
                                    insertStmt.setInt(1, Integer.parseInt(request.getParameter("group_id")));
                                    insertStmt.setString(2, currentUser);
                                    insertStmt.setString(3, messageContent);
                                    insertStmt.setString(4, sentimentCategory);
                                    insertStmt.setDouble(5, sentimentScore);

                                    int rowsInserted = insertStmt.executeUpdate();
                                    if (rowsInserted > 0) {
                                        messageStatus = "<div class='success-message' style='color: #10B981; text-align: center; margin-top: 0.5rem;'><i class='fas fa-check-circle'></i> Message sent!</div>";
                                    }
                                    insertStmt.close();
                                    conn.close();
                                } catch (Exception e) {
                                    messageStatus = "<div class='error-message'><i class='fas fa-exclamation-circle'></i> Error: " + e.getMessage() + "</div>";
                                }
                            }
                        %>
                        <%= messageStatus %>
                    </div>
                </div>
            </div>
        </div>
    </div>

    <script>
        // Get the group ID from the URL parameter
        const groupId = '<%= request.getParameter("group_id") %>';
        
        // Function to update sentiment summary based on hidden fields
        function updateSentimentSummary() {
            const positiveCount = parseInt(document.getElementById('positive-count').value) || 0;
            const neutralCount = parseInt(document.getElementById('neutral-count').value) || 0;
            const negativeCount = parseInt(document.getElementById('negative-count').value) || 0;
            const totalCount = positiveCount + neutralCount + negativeCount;
            
            let overallSentiment = "Neutral";
            let emoji = "😐";
            
            if (positiveCount > negativeCount && positiveCount > neutralCount) {
                overallSentiment = "Positive";
                emoji = "😊";
            } else if (negativeCount > positiveCount && negativeCount > neutralCount) {
                overallSentiment = "Negative";
                emoji = "😔";
            }
            
            const positivePercent = totalCount > 0 ? Math.round((positiveCount / totalCount) * 100) : 0;
            const neutralPercent = totalCount > 0 ? Math.round((neutralCount / totalCount) * 100) : 0;
            const negativePercent = totalCount > 0 ? Math.round((negativeCount / totalCount) * 100) : 0;
            
            const summaryHtml = `
                <div class="sentiment-stats">
                    <div class="sentiment-stat">
                        <span class="sentiment-label">Positive:</span>
                        <span class="sentiment-value sentiment-positive">${positiveCount} (${positivePercent}%)</span>
                    </div>
                    <div class="sentiment-stat">
                        <span class="sentiment-label">Neutral:</span>
                        <span class="sentiment-value sentiment-neutral">${neutralCount} (${neutralPercent}%)</span>
                    </div>
                    <div class="sentiment-stat">
                        <span class="sentiment-label">Negative:</span>
                        <span class="sentiment-value sentiment-negative">${negativeCount} (${negativePercent}%)</span>
                    </div>
                    <div class="sentiment-overall">
                        <span class="sentiment-label">Overall:</span>
                        <span class="sentiment-value">${emoji} ${overallSentiment}</span>
                    </div>
                </div>
            `;
            
            document.getElementById('sentimentSummary').innerHTML = summaryHtml;
        }
        
        // Function to refresh chat messages
        function refreshChat() {
            const xhr = new XMLHttpRequest();
            xhr.open('GET', 'chat_messages.jsp?group_id=' + groupId, true);
            xhr.onload = function() {
                if (xhr.status === 200) {
                    document.getElementById('chat-messages').innerHTML = xhr.responseText;
                    updateSentimentSummary();
                    scrollToBottom();
                }
            };
            xhr.send();
        }
        
        // Function to scroll to bottom of chat
        function scrollToBottom() {
            const chatContainer = document.getElementById('chat-messages');
            chatContainer.scrollTop = chatContainer.scrollHeight;
        }
        
        // Submit message form via AJAX
        document.getElementById('message-form').addEventListener('submit', function(e) {
            e.preventDefault();
            
            const formData = new FormData(this);
            const xhr = new XMLHttpRequest();
            xhr.open('POST', 'send_message.jsp', true);
            xhr.onload = function() {
                if (xhr.status === 200) {
                    document.getElementById('message').value = '';
                    refreshChat();
                }
            };
            xhr.send(formData);
        });
        
        // Start auto-refresh when the page loads
        document.addEventListener('DOMContentLoaded', function() {
            // Initial refresh
            refreshChat();
            
            // Set up auto-refresh every 5 seconds
            setInterval(refreshChat, 5000);
            
            // Scroll to bottom initially
            scrollToBottom();
        });
    </script>
</body>
</html>
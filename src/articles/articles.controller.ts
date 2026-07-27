import {
    Body,
    Controller,
    Delete,
    Get,
    Param,
    Patch,
    Post,
} from '@nestjs/common';
import { CreateArticleDto } from './dtos/create-article.dto';
import { UpdateArticleDto } from './dtos/update-article.dto';
import { ArticlesService } from './articles.service';
import { ApiOperation, ApiResponse, ApiTags } from '@nestjs/swagger';

@ApiTags('article')
@Controller('article')
export class ArticlesController {
    constructor(private articlesService: ArticlesService) {}

    @Get()
    @ApiOperation({ summary: 'Get all articles' })
    @ApiResponse({
        status: 200,
        description: 'Articles retrieved successfully',
    })
    async getArticles() {
        return this.articlesService.findAll();
    }

    @Get(':id')
    @ApiOperation({ summary: 'Get an article by id' })
    @ApiResponse({ status: 200, description: 'Article retrieved successfully' })
    @ApiResponse({ status: 404, description: 'Article not found' })
    async getArticle(@Param('id') id: number) {
        return this.articlesService.findOne(id);
    }

    @Post()
    @ApiOperation({ summary: 'Create a new article' })
    @ApiResponse({ status: 201, description: 'Article created successfully' })
    @ApiResponse({ status: 400, description: 'Invalid article data' })
    async createArticle(@Body() data: CreateArticleDto) {
        return await this.articlesService.create(data);
    }

    @Patch(':id')
    @ApiOperation({ summary: 'Update an article' })
    @ApiResponse({ status: 200, description: 'Article updated successfully' })
    @ApiResponse({ status: 404, description: 'Article not found' })
    async updateArticle(
        @Param('id') id: number,
        @Body() updateArticle: UpdateArticleDto,
    ) {
        return await this.articlesService.update(id, updateArticle);
    }

    @Delete(':id')
    @ApiOperation({ summary: 'Delete an article' })
    @ApiResponse({ status: 200, description: 'Article deleted successfully' })
    @ApiResponse({ status: 404, description: 'Article not found' })
    async deleteArticle(@Param('id') id: number) {
        return this.articlesService.remove(id);
    }
}
